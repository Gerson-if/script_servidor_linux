#!/bin/bash

LOG_FILE="nextcloud_installation.log"

# Função para verificar erros e rastrear falhas, sem quebrar o script
check_error() {
    if [ $? -ne 0 ]; then
        echo "Erro durante: $1" | tee -a $LOG_FILE
        echo "Tentando corrigir o erro automaticamente..." | tee -a $LOG_FILE
        
        # Tentativa de correção automática (apt-get -f install)
        sudo apt-get -f install -y | tee -a $LOG_FILE
        if [ $? -ne 0 ]; then
            echo "Correção automática falhou para: $1" | tee -a $LOG_FILE
        else
            echo "Correção automática bem-sucedida para: $1" | tee -a $LOG_FILE
        fi
    fi
}

# Função para instalar comandos necessários, incluindo os mais básicos
install_prerequisites() {
    echo "Verificando e instalando comandos necessários..." | tee -a $LOG_FILE

    # Verifica e instala sudo se não estiver presente
    if ! command -v sudo &> /dev/null; then
        echo "Sudo não encontrado. Instalando sudo..." | tee -a $LOG_FILE
        apt-get update && apt-get install -y sudo | tee -a $LOG_FILE
        check_error "Instalação do sudo"
    fi

    # Verifica e instala o curl se não estiver presente
    if ! command -v curl &> /dev/null; then
        echo "Curl não encontrado. Instalando curl..." | tee -a $LOG_FILE
        sudo apt-get install -y curl | tee -a $LOG_FILE
        check_error "Instalação do curl"
    fi

    # Verifica e instala o gnupg2 se não estiver presente
    if ! command -v gpg &> /dev/null; then
        echo "GnuPG não encontrado. Instalando gnupg2..." | tee -a $LOG_FILE
        sudo apt-get install -y gnupg2 | tee -a $LOG_FILE
        check_error "Instalação do gnupg2"
    fi

    # Verifica e instala o apt-transport-https se não estiver presente
    if ! dpkg -s apt-transport-https &> /dev/null; then
        echo "Apt-transport-https não encontrado. Instalando apt-transport-https..." | tee -a $LOG_FILE
        sudo apt-get install -y apt-transport-https | tee -a $LOG_FILE
        check_error "Instalação do apt-transport-https"
    fi

    # Verifica e instala o lsb-release se não estiver presente
    if ! command -v lsb_release &> /dev/null; then
        echo "LSB Release não encontrado. Instalando lsb-release..." | tee -a $LOG_FILE
        sudo apt-get install -y lsb-release | tee -a $LOG_FILE
        check_error "Instalação do lsb-release"
    fi

    # Verifica e instala o ca-certificates se não estiver presente
    if ! dpkg -s ca-certificates &> /dev/null; then
        echo "CA Certificates não encontrado. Instalando ca-certificates..." | tee -a $LOG_FILE
        sudo apt-get install -y ca-certificates | tee -a $LOG_FILE
        check_error "Instalação do ca-certificates"
    fi

    echo "Todos os comandos necessários foram instalados ou já estavam presentes." | tee -a $LOG_FILE
}


# Função para solicitar o IP do servidor ONLYOFFICE
get_onlyoffice_ip() {
    read -p "Digite o IP do servidor onde o ONLYOFFICE Document Server está instalado: " onlyoffice_ip
}

# Menu de opções
menu() {
    echo "Selecione uma opção:"
    echo "1) Instalar Nextcloud"
    echo "2) Remover Nextcloud"
    echo "3) Configurar Integração com ONLYOFFICE"
    echo "4) Reverter Integração com ONLYOFFICE"
    echo "5) Sair"
    read -p "Opção: " option
    case $option in
        1) install_nextcloud ;;
        2) remove_nextcloud ;;
        3) configure_integration ;;
        4) revert_integration ;;
        5) exit 0 ;;
        *) echo "Opção inválida"; menu ;;
    esac
}

# Função de instalação
install_nextcloud() {
    echo "Atualizando o sistema..." | tee -a $LOG_FILE
    sudo apt update && sudo apt upgrade -y | tee -a $LOG_FILE
    check_error "Atualização do sistema"

    echo "Instalando dependências..." | tee -a $LOG_FILE
    install_prerequisites
    sudo apt install -y apache2 mariadb-server libapache2-mod-php7.4 php7.4-mysql php7.4-xml php7.4-curl php7.4-zip php7.4-gd php7.4-mbstring php7.4-intl php7.4-bcmath php7.4-gmp | tee -a $LOG_FILE
    check_error "Instalação de dependências"

    echo "Baixando e instalando Nextcloud..." | tee -a $LOG_FILE
    wget https://download.nextcloud.com/server/releases/latest.zip | tee -a $LOG_FILE
    check_error "Download do Nextcloud"
    
    unzip latest.zip | tee -a $LOG_FILE
    sudo mv nextcloud /var/www/html/ | tee -a $LOG_FILE
    sudo chown -R www-data:www-data /var/www/html/nextcloud | tee -a $LOG_FILE
    sudo chmod -R 755 /var/www/html/nextcloud | tee -a $LOG_FILE
    check_error "Instalação do Nextcloud"

    echo "Configurando Apache..." | tee -a $LOG_FILE
    sudo bash -c 'cat > /etc/apache2/sites-available/nextcloud.conf << EOF
    <VirtualHost *:80>
        DocumentRoot /var/www/html/nextcloud
        ServerName $(hostname -I | awk "{print \$1}")

        <Directory /var/www/html/nextcloud/>
            Require all granted
            AllowOverride All
            Options FollowSymLinks MultiViews
            <IfModule mod_dav.c>
                Dav off
            </IfModule>
        </Directory>

        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined

    </VirtualHost>
    EOF' | tee -a $LOG_FILE
    sudo a2ensite nextcloud.conf | tee -a $LOG_FILE
    sudo a2enmod rewrite headers env dir mime | tee -a $LOG_FILE
    sudo systemctl restart apache2 | tee -a $LOG_FILE
    check_error "Configuração do Apache"
    
    echo "Nextcloud instalado com sucesso!" | tee -a $LOG_FILE
}

# Função de remoção
remove_nextcloud() {
    echo "Removendo Nextcloud..." | tee -a $LOG_FILE
    sudo apt remove --purge -y apache2 mariadb-server php7.4 | tee -a $LOG_FILE
    sudo rm -rf /var/www/html/nextcloud /etc/apache2/sites-available/nextcloud.conf /var/lib/mysql /var/log/mysql | tee -a $LOG_FILE
    check_error "Remoção do Nextcloud"

    echo "Nextcloud removido com sucesso!" | tee -a $LOG_FILE
}

# Função de configuração de integração
configure_integration() {
    get_onlyoffice_ip
    echo "Configurando integração com ONLYOFFICE..." | tee -a $LOG_FILE
    sudo apt install -y onlyoffice-nextcloud | tee -a $LOG_FILE
    check_error "Instalação do plugin ONLYOFFICE"

    sudo bash -c "echo 'define(\"ONLYOFFICE_DOCUMENTSERVER_URL\", \"http://$onlyoffice_ip/\");' >> /var/www/html/nextcloud/config/config.php" | tee -a $LOG_FILE
    check_error "Configuração da integração"

    echo "Integração com ONLYOFFICE configurada com sucesso!" | tee -a $LOG_FILE
}

# Função de reversão de integração
revert_integration() {
    echo "Revertendo integração com ONLYOFFICE..." | tee -a $LOG_FILE
    sudo sed -i '/ONLYOFFICE_DOCUMENTSERVER_URL/d' /var/www/html/nextcloud/config/config.php | tee -a $LOG_FILE
    sudo apt remove --purge -y onlyoffice-nextcloud | tee -a $LOG_FILE
    check_error "Reversão da integração"

    echo "Integração com ONLYOFFICE revertida com sucesso!" | tee -a $LOG_FILE
}

# Execução do menu
menu
