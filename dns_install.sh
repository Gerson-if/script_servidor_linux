#!/bin/bash

# Função para garantir que o script é executado com privilégios de superusuário
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Por favor, execute o script como root."
        exit 1
    fi
}

# Função para verificar compatibilidade do sistema operacional
check_os_compatibility() {
    local os_name=$(lsb_release -is)
    local os_version=$(lsb_release -rs)
    
    case "$os_name" in
        "Ubuntu")
            if [[ "$os_version" != "20.04" && "$os_version" != "22.04" && "$os_version" != "24.04" ]]; then
                echo "Este script é compatível apenas com Ubuntu 20.04, 22.04 e 24.04."
                exit 1
            fi
            ;;
        "Debian")
            if [[ "$os_version" != "10" && "$os_version" != "12" ]]; then
                echo "Este script é compatível apenas com Debian 10 e 12."
                exit 1
            fi
            ;;
        *)
            echo "Distribuição não suportada. Este script é compatível apenas com Ubuntu e Debian."
            exit 1
            ;;
    esac
}

# Função para instalar pacotes necessários
install_packages() {
    local packages=("bind9" "bind9utils" "bind9-doc" "apache2" "certbot" "python3-certbot-apache")
    echo "Instalando pacotes necessários..."
    apt-get update -y
    apt-get install -y "${packages[@]}"
}

# Função para obter o endereço IP do servidor
get_server_ip() {
    hostname -I | awk '{print $1}'
}

# Função para obter o gateway padrão
get_default_gateway() {
    ip route | grep default | awk '{print $3}'
}

# Função para obter a máscara de rede
get_netmask() {
    ifconfig | grep -w 'inet' | grep -v '127.0.0.1' | awk '{print $4}'
}

# Função para configurar o BIND9 para um domínio
configure_bind() {
    local domain_name=$1
    local domain_ip=$2

    echo "Configurando BIND9 para o domínio $domain_name com IP $domain_ip..."

    # Configurações principais do BIND
    cat <<EOL >> /etc/bind/named.conf.local
zone "$domain_name" {
    type master;
    file "/etc/bind/zones/db.$domain_name";
};

zone "$(echo $domain_ip | awk -F. '{print $3"."$2"."$1}').in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.$(echo $domain_ip | awk -F. '{print $3"."$2"."$1}')";
};
EOL

    # Diretório de zonas
    mkdir -p /etc/bind/zones

    # Arquivo de zona para o domínio
    cat <<EOL > /etc/bind/zones/db.$domain_name
\$TTL    604800
@       IN      SOA     ns1.$domain_name. admin.$domain_name. (
                         $(date +%Y%m%d%H) ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.$domain_name.
@       IN      A       $domain_ip
ns1     IN      A       $domain_ip
www     IN      A       $domain_ip
EOL

    # Arquivo de zona para o mapeamento reverso
    cat <<EOL > /etc/bind/zones/db.$(echo $domain_ip | awk -F. '{print $3"."$2"."$1}')
\$TTL    604800
@       IN      SOA     ns1.$domain_name. admin.$domain_name. (
                         $(date +%Y%m%d%H) ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.$domain_name.
$(echo $domain_ip | awk -F. '{print $4}')    IN      PTR     ns1.$domain_name.
$(echo $domain_ip | awk -F. '{print $4}')    IN      PTR     www.$domain_name.
EOL

    # Reinicia o BIND9 para aplicar as configurações
    systemctl restart bind9
}

# Função para configurar o Apache para um domínio
configure_apache() {
    local domain_name=$1
    local domain_ip=$2

    echo "Configurando Apache para o domínio $domain_name..."

    # Criando o diretório de documentos para o domínio
    mkdir -p /var/www/$domain_name
    chown -R www-data:www-data /var/www/$domain_name

    # Criando um arquivo de exemplo index.html
    cat <<EOL > /var/www/$domain_name/index.html
<html>
    <head>
        <title>Bem-vindo a $domain_name</title>
    </head>
    <body>
        <h1>Sucesso! O domínio $domain_name está configurado.</h1>
    </body>
</html>
EOL

    # Criando configuração do site Apache
    cat <<EOL > /etc/apache2/sites-available/$domain_name.conf
<VirtualHost *:80>
    ServerAdmin admin@$domain_name
    ServerName $domain_name
    ServerAlias www.$domain_name
    DocumentRoot /var/www/$domain_name
    ErrorLog \${APACHE_LOG_DIR}/$domain_name_error.log
    CustomLog \${APACHE_LOG_DIR}/$domain_name_access.log combined

    <Directory /var/www/$domain_name>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOL

    # Habilitar o site e reconfigurar o Apache
    a2ensite $domain_name.conf
    systemctl reload apache2
}

# Função para configurar SSL/TLS
configure_ssl() {
    local domain_name=$1

    echo "Configurando SSL/TLS para $domain_name..."

    # Verifica se o domínio é público ou local para usar Certbot ou certificado autoassinado
    if [[ "$domain_name" == *.* && "$domain_name" != *.local && "$domain_name" != *.localhost ]]; then
        # Usar Certbot para domínios públicos
        certbot --apache -d $domain_name -d www.$domain_name --non-interactive --agree-tos --email admin@$domain_name
    else
        # Criar certificado SSL autoassinado para domínios locais
        mkdir -p /etc/ssl/$domain_name

        openssl req -new -x509 -days 365 -nodes -out /etc/ssl/$domain_name/ssl.crt -keyout /etc/ssl/$domain_name/ssl.key -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=$domain_name"

        cat <<EOL > /etc/apache2/sites-available/$domain_name-ssl.conf
<VirtualHost *:443>
    ServerAdmin admin@$domain_name
    ServerName $domain_name
    ServerAlias www.$domain_name
    DocumentRoot /var/www/$domain_name
    ErrorLog \${APACHE_LOG_DIR}/$domain_name_error.log
    CustomLog \${APACHE_LOG_DIR}/$domain_name_access.log combined

    SSLEngine on
    SSLCertificateFile /etc/ssl/$domain_name/ssl.crt
    SSLCertificateKeyFile /etc/ssl/$domain_name/ssl.key

    <Directory /var/www/$domain_name>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOL

        # Habilitar o módulo SSL e o site SSL
        a2enmod ssl
        a2ensite $domain_name-ssl.conf
        systemctl reload apache2
    fi
}

# Função para configurar um domínio
configure_domain() {
    local domain_name=$1
    local domain_ip=$2
    configure_bind $domain_name $domain_ip
    configure_apache $domain_name $domain_ip
    configure_ssl $domain_name
}

# Função para exibir o menu principal
menu() {
    while true; do
        echo "Menu de Configuração do Servidor DNS"
        echo "1. Adicionar novo domínio"
        echo "2. Sair"
        read -p "Escolha uma opção: " option

        case $option in
            1)
                read -p "Digite o nome do domínio (exemplo: meudominio.local): " domain_name
                local domain_ip=$(get_server_ip)
                echo "Usando o endereço IP detectado: $domain_ip"
                configure_domain $domain_name $domain_ip
                ;;
            2)
                exit 0
                ;;
            *)
                echo "Opção inválida. Por favor, tente novamente."
                ;;
        esac
    done
}

# Executa as funções
check_root
check_os_compatibility
install_packages
menu
