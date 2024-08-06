#!/bin/bash

# Definir variáveis
APACHE_CONF="/etc/apache2/sites-available/000-default.conf"
SSL_KEY="/etc/ssl/private/apache-selfsigned.key"
SSL_CERT="/etc/ssl/certs/apache-selfsigned.crt"
EMAIL="your_email@example.com"  # Substitua pelo seu e-mail

# Função para encontrar o caminho do php.ini
find_php_ini() {
    local php_ini_path
    php_ini_path=$(php -i | grep "Loaded Configuration File" | awk '{print $4}')
    
    if [ -z "$php_ini_path" ]; then
        echo "Não foi possível encontrar o arquivo php.ini."
        exit 1
    fi
    
    echo $php_ini_path
}

# Função para detectar o IP do localhost
detect_local_ip() {
    local ip
    ip=$(hostname -I | awk '{print $1}')
    echo $ip
}

# Passo 1: Gerar certificado SSL autoassinado
echo "Gerando certificado SSL autoassinado..."
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout $SSL_KEY -out $SSL_CERT \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=localhost/emailAddress=$EMAIL"

# Passo 2: Configurar Apache para usar SSL com localhost
LOCAL_IP=$(detect_local_ip)
echo "Configurando o Apache para usar SSL com o IP $LOCAL_IP e localhost..."
sudo bash -c "cat > $APACHE_CONF <<EOF
<VirtualHost *:443>
    ServerAdmin $EMAIL
    ServerName $LOCAL_IP
    ServerAlias localhost

    DocumentRoot /var/www/html

    SSLEngine on
    SSLCertificateFile $SSL_CERT
    SSLCertificateKeyFile $SSL_KEY

    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF"

# Habilitar módulos e site
echo "Habilitando módulo SSL e configurando o site..."
sudo a2enmod ssl
sudo a2ensite 000-default.conf
sudo systemctl restart apache2

# Passo 3: Ajustar configurações do PHP
PHP_INI=$(find_php_ini)

echo "Ajustando configurações do PHP em $PHP_INI..."
sudo sed -i "s/^memory_limit = .*/memory_limit = 512M/" $PHP_INI
sudo sed -i "s/^upload_max_filesize = .*/upload_max_filesize = 20G/" $PHP_INI
sudo sed -i "s/^post_max_size = .*/post_max_size = 20G/" $PHP_INI

# Reiniciar o Apache para aplicar as mudanças
echo "Reiniciando o Apache..."
sudo systemctl restart apache2

echo "Configuração concluída com sucesso!"
