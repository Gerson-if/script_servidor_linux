#!/bin/bash

# Função para exibir o cabeçalho
function show_header() {
    clear
    echo "###############################################"
    echo "#                Gerenciamento Docker          #"
    echo "###############################################"
}

# Função para instalar o Docker
function install_docker() {
    show_header
    echo "Instalando o Docker..."
    sudo apt-get update
    sudo apt-get upgrade -y
    sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo apt-get autoremove -y
    # Remover chave e repositório antigos, se existirem
    sudo rm -f /usr/share/keyrings/docker-archive-keyring.gpg
    sudo rm -f /etc/apt/sources.list.d/docker.list

    # Adicionar chave GPG oficial do Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Adicionar repositório do Docker
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Atualizar o repositório
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl status docker

    # Remover versões anteriores (caso existam)
    sudo apt-get remove -y docker docker-engine docker.io containerd runc
    
    # Instalar dependências
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

    # Adicionar chave GPG oficial do Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Adicionar repositório do Docker
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Atualizar e instalar o Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "Docker instalado com sucesso!"
    read -p "Pressione qualquer tecla para continuar..."
}

# Função para remover o Docker
function remove_docker() {
    show_header
    echo "ATENÇÃO: Você está prestes a remover o Docker e todos os seus dados."
    read -p "Tem certeza que deseja continuar? (sim/não): " confirmation

    if [[ "$confirmation" == "sim" ]]; then
        read -p "Digite 'REMOVER' para confirmar a remoção total: " final_confirmation
        if [[ "$final_confirmation" == "REMOVER" ]]; then
            echo "Removendo o Docker..."

            # Remover Docker e dependências
            sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            sudo apt-get autoremove -y --purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

            # Remover arquivos de configuração e dados
            sudo rm -rf /var/lib/docker
            sudo rm -rf /var/lib/containerd
            sudo rm -rf /etc/docker

            echo "Docker removido com sucesso!"
        else
            echo "Remoção do Docker cancelada."
        fi
    else
        echo "Remoção do Docker cancelada."
    fi
    read -p "Pressione qualquer tecla para continuar..."
}

# Função para fazer backup de containers Docker
function backup_docker() {
    show_header
    echo "Backup dos containers Docker"
    read -p "Digite o nome do container que deseja fazer o backup: " container_name
    read -p "Digite o caminho do diretório onde deseja salvar o backup: " backup_dir
    read -p "Digite o nome do arquivo de backup (ex: meu_container_backup.tar): " backup_file

    # Realizando o backup
    sudo docker export $container_name > $backup_dir/$backup_file
    echo "Backup do container $container_name realizado em $backup_dir/$backup_file"
    read -p "Pressione qualquer tecla para continuar..."
}

# Função para restaurar backup de containers Docker
function restore_docker() {
    show_header
    echo "Restaurar backup do container Docker"
    read -p "Digite o caminho do arquivo de backup (.tar): " backup_file
    read -p "Digite o nome do novo container: " new_container_name

    # Restaurando o container
    sudo docker import $backup_file $new_container_name
    echo "Container $new_container_name restaurado do backup $backup_file"
    read -p "Pressione qualquer tecla para continuar..."
}

# Função para iniciar um container Docker
function start_container() {
    show_header
    echo "Iniciar container Docker"
    read -p "Digite o nome ou ID do container que deseja iniciar: " container_name
    sudo docker start $container_name
    echo "Container $container_name iniciado com sucesso!"
    read -p "Pressione qualquer tecla para continuar..."
}

# Função para parar um container Docker
function stop_container() {
    show_header
    echo "Parar container Docker"
    read -p "Digite o nome ou ID do container que deseja parar: " container_name
    sudo docker stop $container_name
    echo "Container $container_name parado com sucesso!"
    read -p "Pressione qualquer tecla para continuar..."
}

# Função para visualizar containers Docker em execução
function list_containers() {
    show_header
    echo "Containers Docker em execução:"
    sudo docker ps
    read -p "Pressione qualquer tecla para continuar..."
}

# Função para verificar e corrigir incompatibilidades
function fix_incompatibility() {
    show_header
    echo "Corrigindo incompatibilidades do Docker..."

    # Verificar se o Docker Compose está instalado e na versão correta
    if ! docker compose version >/dev/null 2>&1; then
        echo "Docker Compose não está instalado ou não está configurado corretamente."
        echo "Instalando ou atualizando Docker Compose..."

        # Baixar e instalar Docker Compose
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo "Docker Compose instalado ou atualizado com sucesso!"
    else
        echo "Docker Compose já está instalado e configurado corretamente."
    fi

    read -p "Pressione qualquer tecla para continuar..."
}

# Função para chamar o script de configuração de serviços
function run_service_configurator() {
    show_header
    echo "Executando o configurador de serviços..."

    # Verificar se o script de configuração de serviços existe e é executável
    if [ -x "./configurador_servicos.sh" ]; then
        ./configurador_servicos.sh
    else
        echo "O script de configuração de serviços não foi encontrado ou não é executável."
    fi

    read -p "Pressione qualquer tecla para continuar..."
}

# Função para exibir o menu
function show_menu() {
    while true; do
        show_header
        echo "1. Instalar Docker"
        echo "2. Remover Docker"
        echo "3. Backup de Container Docker"
        echo "4. Restaurar Container Docker"
        echo "5. Iniciar Container Docker"
        echo "6. Parar Container Docker"
        echo "7. Visualizar Containers em Execução"
        echo "8. Corrigir Incompatibilidades"
        echo "9. Configurador de Serviços"
        echo "10. Sair"
        echo
        read -p "Escolha uma opção [1-10]: " choice

        case $choice in
            1) install_docker ;;
            2) remove_docker ;;
            3) backup_docker ;;
            4) restore_docker ;;
            5) start_container ;;
            6) stop_container ;;
            7) list_containers ;;
            8) fix_incompatibility ;;
            9) run_service_configurator ;;
            10) exit ;;
            *) echo "Opção inválida. Por favor, tente novamente." ;;
        esac
    done
}

# Executar o menu
show_menu
