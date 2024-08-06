#!/bin/bash

# Função para exibir mensagens de erro e sair
error_exit() {
    echo "$1" 1>&2
    exit 1
}

# Função para perguntar e validar a versão do PHP
select_php_version() {
    echo "Escolha a versão do PHP que você deseja instalar:"
    PS3='Digite o número da versão desejada: '
    options=("PHP 5.6" "PHP 7.0" "PHP 7.4" "PHP 8.0" "Última versão disponível" "Sair")
    select opt in "${options[@]}"; do
        case $opt in
            "PHP 5.6") php_version="5.6"; break ;;
            "PHP 7.0") php_version="7.0"; break ;;
            "PHP 7.4") php_version="7.4"; break ;;
            "PHP 8.0") php_version="8.0"; break ;;
            "Última versão disponível") php_version="latest"; break ;;
            "Sair") error_exit "Saindo do script." ;;
            *) echo "Opção inválida. Tente novamente." ;;
        esac
    done
}

# Função para selecionar os módulos e extensões
select_modules() {
    echo "Selecione os módulos e extensões que você deseja instalar (separe os números por vírgula para múltiplas seleções):"
    modules=("php-mysql" "php-xml" "php-mbstring" "php-curl" "php-zip" "php-gd" "php-intl" "php-bcmath" "php-imagick" "php-opcache" "php-readline" "php-dom" "php-xmlwriter" "php-xmlreader" "php-libxml" "php-simplexml")
    options=("${modules[@]}" "Todos os módulos" "Nenhum módulo")
    for i in "${!options[@]}"; do
        echo "$((i+1))) ${options[$i]}"
    done
    
    read -p "Digite os números das opções desejadas ou 0 para finalizar: " module_choices
    IFS=',' read -r -a selected_choices <<< "$module_choices"

    selected_modules=()
    for choice in "${selected_choices[@]}"; do
        case $choice in
            [1-9]|1[0-7]) selected_modules+=("${modules[$((choice-1))]}") ;;
            18) selected_modules=(); break ;;
            17) selected_modules=("${modules[@]}"); break ;;
            0) break ;;
            *) echo "Opção inválida: $choice. Tente novamente." ;;
        esac
    done

    selected_modules=($(echo "${selected_modules[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

    echo "Módulos selecionados: ${selected_modules[@]}"
    read -p "Você deseja instalar apenas esses módulos? (s/n): " confirm
    if [[ $confirm != "s" && $confirm != "S" ]]; then
        select_modules
    fi
}

# Função para verificar a distribuição e versão do SO
check_os_version() {
    os_name=$(lsb_release -is)
    os_version=$(lsb_release -rs)

    case "$os_name" in
        "Ubuntu")
            [[ "$os_version" =~ ^(20\.04|22\.04|24\.04)$ ]] || error_exit "Este script só é compatível com Ubuntu 20.04, 22.04 e 24.04."
            ;;
        "Zorin")
            [[ "$os_version" == "16" ]] || error_exit "Este script só é compatível com Zorin 16."
            ;;
        "Debian")
            [[ "$os_version" =~ ^(10|12)$ ]] || error_exit "Este script só é compatível com Debian 10 e 12."
            ;;
        *)
            error_exit "Distribuição não suportada. Este script só é compatível com Ubuntu, Zorin e Debian."
            ;;
    esac
}

# Função para adicionar repositórios PHP
add_php_repository() {
    echo "Adicionando o repositório do PHP..."
    case "$os_name" in
        "Ubuntu"|"Zorin")
            sudo add-apt-repository -y ppa:ondrej/php || error_exit "Falha ao adicionar o repositório do PHP."
            ;;
        "Debian")
            echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
            wget -qO - https://packages.sury.org/php/apt.gpg | sudo apt-key add -
            ;;
    esac
}

# Função para instalar PHP e módulos
install_php_and_modules() {
    local version="$1"
    local modules="$2"

    echo "Instalando PHP $version e módulos necessários..."

    if [ "$version" = "latest" ]; then
        sudo apt install -y php php-cli php-fpm || error_exit "Falha ao instalar o PHP."
    else
        sudo apt install -y php"$version" php"$version"-cli php"$version"-fpm || error_exit "Falha ao instalar o PHP $version."
    fi

    if [ -n "$modules" ]; then
        sudo apt install -y $(echo $modules | sed "s/[^ ]* */php$version-&/g") || error_exit "Falha ao instalar módulos PHP $version."
    fi
}

# Função para configurar Apache e Nginx
configure_web_servers() {
    if command -v apache2 > /dev/null; then
        echo "Configurando o Apache para usar o PHP $php_version..."
        sudo a2dismod php$(ls /etc/apache2/mods-enabled | grep php | awk -F'-' '{print $2}' | head -n 1) || error_exit "Falha ao desativar módulo PHP anterior."
        sudo a2enmod php$php_version || error_exit "Falha ao ativar módulo PHP $php_version."
        sudo systemctl restart apache2 || error_exit "Falha ao reiniciar o Apache."
        echo "Apache configurado para usar PHP $php_version."
    else
        echo "Apache não encontrado. Pulando configuração do Apache."
    fi

    if command -v nginx > /dev/null; then
        echo "Configurando o Nginx para usar o PHP $php_version..."
        sed -i "s|unix:/run/php/php[0-9.]*-fpm.sock|unix:/run/php/php$php_version-fpm.sock|g" /etc/nginx/sites-available/default
        sudo systemctl restart nginx || error_exit "Falha ao reiniciar o Nginx."
        echo "Nginx configurado para usar PHP $php_version."
    else
        echo "Nginx não encontrado. Pulando configuração do Nginx."
    fi
}

# Função principal
main() {
    select_php_version
    select_modules
    check_os_version

    echo "Atualizando o índice dos pacotes..."
    sudo apt update || {
        echo "Sincronizando o tempo do sistema..."
        sudo ntpdate ntp.ubuntu.com || error_exit "Falha ao sincronizar o tempo do sistema."
        sleep 120
        sudo apt update || error_exit "Falha ao atualizar o índice dos pacotes."
    }

    echo "Instalando o software-properties-common..."
    sudo apt install -y software-properties-common || error_exit "Falha ao instalar o software-properties-common."

    add_php_repository

    echo "Atualizando o índice dos pacotes novamente..."
    sudo apt update || error_exit "Falha ao atualizar o índice dos pacotes."

    echo "Configurando o sistema para usar UTF-8..."
    sudo locale-gen "en_US.UTF-8" || error_exit "Falha ao gerar a localidade en_US.UTF-8."
    sudo update-locale LANG=en_US.UTF-8 || error_exit "Falha ao atualizar a localidade padrão."

    install_php_and_modules "$php_version" "${selected_modules[@]}"

    php_installed=$(php -v 2>/dev/null)
    [ -z "$php_installed" ] && error_exit "PHP não foi instalado corretamente. Verifique os logs para mais detalhes."
    echo "PHP instalado com sucesso: $php_installed"

    configure_web_servers

    echo "Instalação e configuração concluídas com sucesso!"
}

# Chama a função principal
main
