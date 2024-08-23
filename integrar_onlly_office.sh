#!/bin/bash

# Função para solicitar entrada do usuário com validação
function input {
    while true; do
        read -p "$1: " value
        if [ -z "$value" ]; then
            echo "Entrada inválida. Por favor, tente novamente."
        else
            echo $value
            break
        fi
    done
}

# Função para confirmar os dados
function confirm {
    echo "$1: $2"
    read -p "Está correto? (s/n) " confirm
    if [ "$confirm" != "s" ]; then
        echo "Por favor, execute o script novamente e forneça os dados corretos."
        exit 1
    fi
}

# Solicitar informações do usuário
echo "Bem-vindo ao script de configuração do ONLYOFFICE Document Server para Nextcloud."
DOCUMENT_SERVER_URL=$(input "Informe o URL completo do ONLYOFFICE Document Server (ex.: http://10.56.224.94:8080)")
NEXTCLOUD_URL=$(input "Informe o URL completo do Nextcloud (ex.: http://10.56.224.94/nextcloud)")

# Confirmar dados
echo
confirm "URL do ONLYOFFICE Document Server" "$DOCUMENT_SERVER_URL"
confirm "URL do Nextcloud" "$NEXTCLOUD_URL"

# Configuração de integração com o Nextcloud
echo "Configurando integração com o Nextcloud..."
sudo -u www-data php /var/www/nextcloud/occ config:system:set onlyoffice DocumentServerUrl --value="${DOCUMENT_SERVER_URL}" || { echo "Erro ao configurar o DocumentServerUrl."; exit 1; }
sudo -u www-data php /var/www/nextcloud/occ config:system:set onlyoffice DocumentServerInternalUrl --value="${DOCUMENT_SERVER_URL}" || { echo "Erro ao configurar o DocumentServerInternalUrl."; exit 1; }
sudo -u www-data php /var/www/nextcloud/occ config:system:set onlyoffice StorageUrl --value="${NEXTCLOUD_URL}" || { echo "Erro ao configurar o StorageUrl."; exit 1; }

echo "Configuração do ONLYOFFICE Document Server com Nextcloud concluída com sucesso!"
