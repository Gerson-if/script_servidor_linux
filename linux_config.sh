#!/bin/bash

# Atualizar repositório
sudo apt update

# Desinstalar MariaDB e suas dependências completamente
sudo apt purge -y mariadb-server* mariadb-client* mysql* libmysql* 

# Remover quaisquer arquivos de configuração restantes
sudo rm -rf /etc/mysql /var/lib/mysql /etc/my.cnf /etc/mysql*conf.d /var/log/mysql*

# Limpar quaisquer dependências restantes
sudo apt autoremove -y

# Instalar Apache e PHP com extensões necessárias
sudo apt install -y apache2 php libapache2-mod-php php-mysql php-intl php-ldap php-apcu php-xmlrpc php-mbstring php-curl php-gd php-simplexml php-zip php-bz2 php-sodium

# Verificar se o Apache e o PHP foram instalados corretamente
if ! command -v apache2 &> /dev/null || ! command -v php &> /dev/null; then
    echo "Erro ao instalar Apache e PHP. Verifique o log para mais detalhes."
    exit 1
fi

# Verificar se a extensão Zend OPcache está habilitada
if php -m | grep -q opcache; then
    echo "A extensão Zend OPcache está habilitada."
else
    echo "A extensão Zend OPcache não está habilitada."
fi

# Reiniciar o Apache
sudo systemctl restart apache2
echo "Apache reiniciado com sucesso."

# Instalar o MariaDB
sudo apt install -y mariadb-server

# Reiniciar o serviço MariaDB
sudo systemctl restart mariadb

# Informar ao usuário sobre a configuração de segurança
echo "Você será guiado pelo script de segurança do MariaDB. Escolha 'n' para as opções de remoção de acesso remoto root e exclusão de banco de dados de teste para evitar configurações restritivas."
sleep 3

# Executar o script de segurança do MariaDB
sudo mysql_secure_installation

# Conceder todos os privilégios ao usuário root
echo "Digite a senha de root do MariaDB para conceder os privilégios:"
read -s db_password
echo "Concedendo privilégios..."
sudo mysql -u root -p"$db_password" -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY '$db_password' WITH GRANT OPTION; FLUSH PRIVILEGES;"

# Verificar extensões PHP habilitadas
echo "Extensões PHP habilitadas:"
php -m