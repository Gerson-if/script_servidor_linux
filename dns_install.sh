#!/bin/bash

# Função para garantir que o script é executado como root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "\e[31m[ERRO]\e[0m Por favor, execute o script como root."
        exit 1
    fi
}

# Função para verificar compatibilidade do sistema operacional
check_os_compatibility() {
    local os_name=$(lsb_release -is)
    local os_version=$(lsb_release -rs)
    
    if [[ "$os_name" != "Ubuntu" && "$os_name" != "Debian" ]]; then
        echo -e "\e[31m[ERRO]\e[0m Distribuição não suportada. Este script é compatível apenas com Ubuntu e Debian."
        exit 1
    fi
}

# Função para remover completamente configurações anteriores do BIND9
clean_previous_config() {
    echo -e "\e[32m[INFO]\e[0m Removendo configurações anteriores do BIND9..."

    # Parando o serviço BIND9
    systemctl stop bind9

    # Removendo pacotes e diretórios do BIND9
    apt-get purge --auto-remove -y bind9 bind9utils bind9-doc
    rm -rf /etc/bind
    rm -rf /var/cache/bind

    # Limpando qualquer resquício de arquivos de configuração
    rm -f /etc/default/bind9
    rm -f /etc/init.d/bind9

    echo -e "\e[32m[INFO]\e[0m Configurações anteriores removidas com sucesso."
}

# Função para instalar pacotes necessários
install_packages() {
    echo -e "\e[32m[INFO]\e[0m Instalando pacotes necessários..."
    apt-get update -y && apt-get install -y bind9 bind9utils bind9-doc
    echo -e "\e[32m[INFO]\e[0m Pacotes instalados com sucesso."
}

# Função para configurar o BIND9 para um domínio local
configure_bind_local() {
    local domain_name
    local domain_ip

    read -p "Digite o nome do domínio (ex: exemplo.local): " domain_name
    read -p "Digite o endereço IP para o domínio: " domain_ip

    echo -e "\e[32m[INFO]\e[0m Configurando BIND9 para o domínio $domain_name..."

    # Criando diretório de zonas
    mkdir -p /etc/bind/zones

    # Configurando o named.conf.local
    echo "zone \"$domain_name\" {
    type master;
    file \"/etc/bind/zones/db.$domain_name\";
};" >> /etc/bind/named.conf.local

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

    # Reiniciando o BIND9 para aplicar as configurações
    if ! systemctl restart bind9; then
        echo -e "\e[31m[ERRO]\e[0m Erro ao reiniciar o BIND9. Verifique a configuração."
        exit 1
    else
        echo -e "\e[32m[SUCESSO]\e[0m Domínio $domain_name configurado com sucesso."
    fi
}

# Função para listar domínios configurados
list_domains() {
    echo -e "\e[32m[INFO]\e[0m Domínios configurados:"
    grep 'zone "' /etc/bind/named.conf.local | awk '{print $2}' | sed 's/"//g'
}

# Função para remover um domínio local
remove_domain() {
    local domain_name

    list_domains
    read -p "Digite o nome do domínio que deseja remover: " domain_name

    # Removendo a configuração do domínio no named.conf.local
    sed -i "/zone \"$domain_name\" {/,/};/d" /etc/bind/named.conf.local

    # Removendo o arquivo de zona
    rm -f /etc/bind/zones/db.$domain_name

    # Reiniciando o BIND9 para aplicar as alterações
    if ! systemctl restart bind9; then
        echo -e "\e[31m[ERRO]\e[0m Erro ao reiniciar o BIND9. Verifique a configuração."
        exit 1
    else
        echo -e "\e[32m[SUCESSO]\e[0m Domínio $domain_name removido com sucesso."
    fi
}

# Função para testar a configuração DNS
test_dns_configuration() {
    local domain_name

    read -p "Digite o nome do domínio para testar (ex: exemplo.local): " domain_name

    echo -e "\e[32m[INFO]\e[0m Testando resolução DNS para $domain_name..."

    if host $domain_name 127.0.0.1 > /dev/null; then
        echo -e "\e[32m[SUCESSO]\e[0m O domínio $domain_name está resolvendo corretamente na rede local."
    else
        echo -e "\e[31m[ERRO]\e[0m Falha na resolução DNS. Verifique a configuração."
    fi
}

# Função para o menu principal
main_menu() {
    while true; do
        echo -e "\n\e[34mMenu Principal:\e[0m"
        echo "1. Instalar e Configurar BIND9 (Nova Instalação)"
        echo "2. Cadastrar Novo Domínio Local"
        echo "3. Listar Domínios Configurados"
        echo "4. Remover um Domínio"
        echo "5. Testar Resolução DNS"
        echo "6. Sair"

        read -p "Escolha uma opção: " option

        case $option in
            1)
                clean_previous_config
                install_packages
                ;;
            2)
                configure_bind_local
                ;;
            3)
                list_domains
                ;;
            4)
                remove_domain
                ;;
            5)
                test_dns_configuration
                ;;
            6)
                echo -e "\e[32m[INFO]\e[0m Saindo..."
                exit 0
                ;;
            *)
                echo -e "\e[31m[ERRO]\e[0m Opção inválida. Tente novamente."
                ;;
        esac
    done
}

# Execução do script
check_root
check_os_compatibility
main_menu
