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
    options=("PHP 5.6" "PHP 7.0" "PHP 7.1" "PHP 7.2" "PHP 7.3" "PHP 7.4" "PHP 8.0" "Última versão disponível" "Sair")
    select opt in "${options[@]}"; do
        case $opt in
            "PHP 5.6") php_version="5.6"; break ;;
            "PHP 7.0") php_version="7.0"; break ;;
            "PHP 7.1") php_version="7.1"; break ;;
            "PHP 7.2") php_version="7.2"; break ;;
            "PHP 7.3") php_version="7.3"; break ;;
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
    modules=("mysql" "xml" "mbstring" "curl" "zip" "gd" "intl" "bcmath" "imagick" "opcache" "readline" "dom" "xmlwriter" "xmlreader" "libxml" "simplexml")
    options=("${modules[@]}" "Nenhum módulo")
    
    for i in "${!options[@]}"; do
        echo "$((i+1))) ${options[$i]}"
    done
    
    read -p "Digite os números das opções desejadas ou 0 para finalizar: " module_choices
    IFS=',' read -r -a selected_choices <<< "$module_choices"

    selected_modules=()
    for choice in "${selected_choices[@]}"; do
        case $choice in
            [1-9]|1[0-6]) selected_modules+=("${modules[$((choice-1))]}") ;;
            17) selected_modules=(); break ;;
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
            [[ "$os_version" =~ ^(16\.04|18\.04|20\.04|22\.04|24\.04)$ ]] || error_exit "Este script só é compatível com Ubuntu 16.04 e versões mais recentes."
            ;;
        "Debian")
            [[ "$os_version" =~ ^(10|11)$ ]] || error_exit "Este script só é compatível com Debian 10 e 11."
            ;;
        *)
            error_exit "Distribuição não suportada. Este script só é compatível com Ubuntu e Debian."
            ;;
    esac
}

# Função para adicionar repositórios PHP
add_php_repository() {
    echo "Adicionando o repositório do PHP..."
    case "$os_name" in
        "Ubuntu"|"Debian")
            sudo add-apt-repository -y ppa:ondrej/php || error_exit "Falha ao adicionar o repositório do PHP."
            ;;
    esac
}

# Função para forçar a remoção de arquivos e pacotes, mesmo que não estejam vazios
force_remove() {
    local path="$1"
    echo "Forçando a remoção de $path..."
    sudo rm -rf "$path" || error_exit "Falha ao remover $path."
}

# Função para remover completamente versões anteriores do PHP
remove_previous_php_versions() {
    echo "Removendo versões anteriores do PHP..."
    sudo apt-get purge -y 'php*' || error_exit "Falha ao remover versões anteriores do PHP."
    sudo apt-get autoremove -y || error_exit "Falha ao remover dependências desnecessárias."
    sudo apt-get autoclean || error_exit "Falha ao limpar o cache do apt."
    force_remove /etc/php
    force_remove /var/lib/php
    echo "Versões anteriores do PHP removidas com sucesso."
}

# Função para reinstalar e configurar o Apache
reinstall_apache() {
    echo "Reinstalando o Apache..."
    sudo apt-get purge -y apache2 || error_exit "Falha ao remover o Apache."
    sudo apt-get autoremove -y || error_exit "Falha ao remover dependências desnecessárias."
    sudo apt-get autoclean || error_exit "Falha ao limpar o cache do apt."
    
    echo "Instalando o Apache..."
    sudo apt-get install -y apache2 || error_exit "Falha ao instalar o Apache."

    echo "Verificando a instalação do módulo PHP..."
    if ! dpkg -l | grep "libapache2-mod-php$php_version" > /dev/null; then
        echo "Módulo PHP não encontrado, tentando instalação alternativa..."
        sudo apt-get install -y libapache2-mod-php$php_version || error_exit "Falha ao instalar o módulo PHP para a versão $php_version."
    fi

    echo "Configurando o Apache para usar o PHP $php_version..."
    if [ -e /usr/lib/apache2/modules/libphp$php_version.so ]; then
        # Desativa o módulo PHP atual e ativa o novo módulo
        current_php_module=$(apache2ctl -M 2>&1 | grep -oP 'php\d+\.\d+')
        if [ -n "$current_php_module" ]; then
            sudo a2dismod "$current_php_module" || error_exit "Falha ao desativar o módulo PHP anterior."
        fi
        
        sudo a2enmod "php$php_version" || error_exit "Falha ao ativar o módulo PHP $php_version."
        sudo systemctl restart apache2 || error_exit "Falha ao reiniciar o Apache."
    else
        error_exit "O módulo PHP $php_version não foi encontrado no Apache."
    fi
}

# Função para verificar se todos os módulos PHP necessários estão instalados
check_php_modules() {
    echo "Verificando se todos os módulos PHP necessários estão instalados..."
    missing_modules=()
    
    # Verifica módulos e extensões
    for module in ${selected_modules[@]}; do
        if ! php -m | grep -i "$module" > /dev/null; then
            missing_modules+=("$module")
        fi
    done

    if [ ${#missing_modules[@]} -eq 0 ]; then
        echo "Todos os módulos PHP necessários estão instalados."
    else
        echo "Os seguintes módulos PHP estão faltando: ${missing_modules[@]}"
        echo "Tentando instalar os módulos faltantes..."

        for module in ${missing_modules[@]}; do
            echo "Tentando instalar o módulo $module..."
            if ! sudo apt-get install -y "php$php_version-$module" > /dev/null 2>&1; then
                echo "Falha ao instalar o módulo $module com o comando padrão. Tentando pacotes alternativos..."
                # Tentativas alternativas de instalação
                if ! sudo apt-get install -y "php-$module" > /dev/null 2>&1; then
                    echo "Falha ao instalar o módulo $module com pacotes alternativos."
                fi
            fi
        done

        # Reinicia o Apache para aplicar as mudanças
        sudo systemctl restart apache2 || error_exit "Falha ao reiniciar o Apache."
    fi
}

# Função para instalar PHP e módulos
install_php_and_modules() {
    local version="$1"
    local modules="$2"

    echo "Instalando PHP $version e módulos necessários..."

    sudo apt-get update || error_exit "Falha ao atualizar o índice dos pacotes."
    sudo apt-get install -y software-properties-common || error_exit "Falha ao instalar o software-properties-common."
    add_php_repository
    sudo apt-get update || error_exit "Falha ao atualizar o índice dos pacotes."

    if [ "$version" = "latest" ]; then
        sudo apt-get install -y php php-cli php-fpm || error_exit "Falha ao instalar a última versão do PHP."
    else
        sudo apt-get install -y php$version php$version-cli php$version-fpm || error_exit "Falha ao instalar o PHP $version."
    fi

    if [ -n "$modules" ]; then
        for module in ${modules[@]}; do
            sudo apt-get install -y "php$version-$module" || error_exit "Falha ao instalar o módulo $module."
        done
    fi

    sudo systemctl restart apache2 || error_exit "Falha ao reiniciar o Apache."
    echo "PHP $version e módulos instalados com sucesso."
}

# Main script
check_os_version
select_php_version
select_modules
remove_previous_php_versions
reinstall_apache
install_php_and_modules "$php_version" "${selected_modules[@]}"
check_php_modules

echo "Instalação e configuração do PHP e Apache concluídas com sucesso!"
