# Usando a imagem oficial do MariaDB
FROM mariadb:latest

# Definindo a senha root padrão
ENV MARIADB_ROOT_PASSWORD=root

# Copiando o arquivo de configuração
COPY my.cnf /etc/mysql/conf.d/my.cnf

# Expondo a porta 3306 para permitir conexões
EXPOSE 3306
