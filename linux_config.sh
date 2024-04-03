#!/bin/bash

# Verificar permissões de execução
if [ ! -x "$(command -v sudo)" ]; then
    echo "Por favor, execute este script como root ou com permissões de sudo."
    exit 1
fi

# Função para verificar se o pacote está instalado
package_installed() {
    dpkg -l | grep -q $1
}

# Função para remover pacote se estiver instalado
remove_package_if_installed() {
    if package_installed $1; then
        sudo apt remove --purge $1 -y
        sudo apt autoremove -y
    fi
}

# Função para verificar se o serviço está em execução
service_running() {
    sudo systemctl is-active --quiet $1
    return $?
}

# Função para verificar a conexão do MySQL
check_mysql_connection() {
    mysqladmin ping &>/dev/null
    if [ $? -eq 0 ]; then
        echo "Conexão com o MySQL bem-sucedida."
    else
        echo "Falha na conexão com o MySQL. Verifique as configurações."
        exit 1
    fi
}

# Função para instalar e configurar o Apache, MySQL, PHP, PHPMyAdmin, Adminer, SSH e FTP
install_configure_all() {
    echo "Iniciando a instalação e configuração de todos os componentes..."
    
    # Instalar Apache
    sudo apt update
    sudo apt install apache2 -y
    sudo ufw allow in "Apache Full"
    sudo chmod -R 777 /var/www/html

    # Instalar MySQL
    remove_package_if_installed mysql-server
    sudo apt install mysql-server -y
    sudo mysql_secure_installation
    check_mysql_connection
    sudo mysql -e "CREATE DATABASE IF NOT EXISTS mydatabase;"
    sudo mysql -e "CREATE USER 'admin'@'localhost' IDENTIFIED BY 'admin_123';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON mydatabase.* TO 'admin'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"

    # Instalar PHP e PHPMyAdmin
    remove_package_if_installed php libapache2-mod-php php-mysql php-cli php-mbstring php-json php-curl php-gd phpmyadmin -y
    sudo apt install php libapache2-mod-php php-mysql php-cli php-mbstring php-json php-curl php-gd phpmyadmin -y
    sudo phpenmod mbstring

    # Configurar UTF-8
    sudo echo "<Directory /var/www/html>
        AddDefaultCharset UTF-8
</Directory>" | sudo tee /etc/apache2/conf-available/charset.conf
    sudo a2enconf charset.conf
    sudo systemctl restart apache2

    # Configurar permissões do Apache
    sudo chmod -R 777 /var/www/html

    # Instalar e configurar Adminer
    remove_package_if_installed adminer
    sudo mkdir /usr/share/adminer
    sudo wget "http://www.adminer.org/latest.php" -O /usr/share/adminer/latest.php
    sudo ln -s /usr/share/adminer/latest.php /usr/share/adminer/adminer.php
    echo "Alias /adminer.php /usr/share/adminer/adminer.php" | sudo tee /etc/apache2/conf-available/adminer.conf
    sudo a2enconf adminer.conf
    sudo systemctl restart apache2

    # Instalar e configurar SSH
    remove_package_if_installed openssh-server
    sudo apt install openssh-server -y
    sudo systemctl enable ssh
    sudo systemctl start ssh
    sudo ufw allow ssh

    # Instalar e configurar FTP
    remove_package_if_installed vsftpd
    sudo apt install vsftpd -y
    sudo systemctl enable vsftpd
    sudo systemctl start vsftpd
    sudo ufw allow ftp

    echo "Todos os componentes foram instalados e configurados com sucesso."
}

# Remover instalações anteriores se existirem
remove_package_if_installed apache2
remove_package_if_installed mysql-server
remove_package_if_installed php
remove_package_if_installed phpmyadmin
remove_package_if_installed adminer
remove_package_if_installed openssh-server
remove_package_if_installed vsftpd

# Menu interativo
echo "---------------------------------------------------------"
echo "          Bem-vindo ao instalador Apache, MySQL,         "
echo "            PHP, PHPMyAdmin, Adminer, SSH e FTP!         "
echo "---------------------------------------------------------"
echo "Este script irá instalar e configurar todos os         "
echo "componentes necessários para um ambiente de desenvolvimento. "
echo "Por favor, certifique-se de ter sua senha de banco de  "
echo "dados em mãos.                                         "
echo "Senha do banco de dados: admin_123                     "
echo "Usuário do banco de dados: admin                       "
echo "Por favor, altere essas credenciais após a instalação  "
echo "por motivos de segurança.                              "
echo "---------------------------------------------------------"
echo "Selecione a opção para continuar:"

options=("Instalar e Configurar Tudo" "Sair")
select opt in "${options[@]}"; do
    case $opt in
        "Instalar e Configurar Tudo")
            install_configure_all
            ;;
        "Sair")
            echo "Saindo do instalador."
            exit 0
            ;;
        *)
            echo "Opção inválida. Por favor, escolha uma opção válida."
            ;;
    esac
done
