#!/bin/bash

# Função para exibir mensagens de erro e sair
function error_exit {
    echo "$1" 1>&2
    exit 1
}

# Função para verificar se um comando está disponível
function check_command {
    command -v "$1" >/dev/null 2>&1 || error_exit "$2"
}

# Função para atualizar o sistema
function update_system {
    echo "Atualizando o sistema..."
    sudo apt update && sudo apt upgrade -y || error_exit "Falha na atualização do sistema."
}

# Função para instalar o Git
function install_git {
    echo "Instalando o Git..."
    sudo apt install -y git || error_exit "Falha na instalação do Git."
}

# Função para configurar o ONLYOFFICE após o Nextcloud
function setup_onlyoffice {
    echo "Baixando o container ONLYOFFICE..."
    git clone https://github.com/ONLYOFFICE/docker-onlyoffice-nextcloud || error_exit "Falha ao clonar o repositório do ONLYOFFICE."

    echo "Entrando no diretório do ONLYOFFICE..."
    cd docker-onlyoffice-nextcloud/ || error_exit "Falha ao entrar no diretório do repositório do ONLYOFFICE."

    echo "Verificando Docker e Docker Compose..."
    check_command "docker" "Docker não está instalado. Por favor, instale o Docker para continuar."
    check_command "docker-compose" "Docker Compose não está instalado. Por favor, instale o Docker Compose para continuar."

    echo "Subindo containers do ONLYOFFICE e Nextcloud..."
    sudo docker-compose up -d || error_exit "Falha ao subir os containers do ONLYOFFICE e Nextcloud."
}

# Função para executar o script de integração do ONLYOFFICE com Nextcloud
function run_onlyoffice_integration_script {
    echo "Certifique-se de que o Nextcloud está funcionando e que você fez login pelo menos uma vez antes de executar este script."
    echo "Configurando ONLYOFFICE Online..."
    if [ -f "set_configuration.sh" ]; then
        bash set_configuration.sh || error_exit "Falha na configuração do ONLYOFFICE."
    else
        error_exit "Arquivo set_configuration.sh não encontrado."
    fi
}

# Função para exibir informações sobre Docker e Docker Compose
function show_info {
    clear
    echo "Informações sobre Docker e Docker Compose:"
    echo
    echo "Docker é uma plataforma para desenvolver, enviar e executar aplicativos em containers."
    echo "Containers são ambientes leves e portáteis que garantem que o aplicativo funcione"
    echo "da mesma forma em qualquer lugar, independentemente do sistema operacional ou hardware."
    echo
    echo "Docker Compose é uma ferramenta para definir e executar aplicativos Docker multi-container."
    echo "Com Compose, você usa um arquivo YAML para configurar todos os serviços do seu aplicativo."
    echo "Depois, com um único comando, você pode iniciar todos os serviços a partir da configuração."
    echo
    echo "Para mais informações, visite: https://docs.docker.com/get-docker/ e https://docs.docker.com/compose/"
    echo
    read -p "Pressione [Enter] para voltar ao menu principal..."
}

# Função para exibir o menu
function show_menu {
    clear
    echo "============================================="
    echo "            Instalador de Serviços           "
    echo "============================================="
    echo "1) Atualizar o sistema"
    echo "2) Instalar Git"
    echo "3) Configurar ONLYOFFICE com NEXTCLOUD"
    echo "4) Executar script de integração do ONLYOFFICE com Nextcloud (Nextcloud deve estar funcionando e você deve ter feito login pelo menos uma vez)"
    echo "5) Informações sobre Docker e Docker Compose"
    echo "6) Sair"
    echo "============================================="
}

# Função principal do script
function main {
    while true; do
        show_menu
        read -p "Digite o número da opção desejada: " option
        case $option in
            1)
                update_system
                ;;
            2)
                install_git
                ;;
            3)
                setup_onlyoffice
                ;;
            4)
                run_onlyoffice_integration_script
                ;;
            5)
                show_info
                ;;
            6)
                echo "Saindo..."
                exit 0
                ;;
            *)
                echo "Opção inválida. Tente novamente."
                ;;
        esac
    done
}

# Executa a função principal
main
