# Sistema de Configuração para Ambiente de Desenvolvimento Linux - Versão 1.0.3

Este projeto oferece um sistema automatizado para a configuração de um ambiente de desenvolvimento em Linux, especificamente projetado para Ubuntu. Utiliza uma interface de menu para simplificar a instalação e configuração de componentes essenciais como Apache, PHP e MariaDB, além de facilitar a manutenção básica do sistema.

## Componentes Instalados

- **Apache**: Servidor web robusto para hospedagem de páginas.
- **PHP**: Linguagem de script do lado do servidor, incluindo várias extensões como `php-mysql`, `php-intl`, e outras.
- **MariaDB**: Sistema de gerenciamento de banco de dados, uma alternativa ao MySQL.
- **Adminer**: Ferramenta de administração de banco de dados em PHP.

## Requisitos

- **Ubuntu** (testado na versão 18.04 LTS ou superior)
- **Permissões de superusuário** (`sudo`)

## Uso

1. **Faça o download do pacote do script**:  
   Baixe o arquivo compactado script_servidor_linux-main.zip do seguinte link: [Download do Pacote](https://github.com/Gerson-if/script_servidor_linux/archive/refs/heads/main.zip).

2. **Instale o pacote `unzip`**: Caso ainda não esteja instalado, instale o `unzip` com o comando:

   sudo apt update
   sudo apt install unzip

3. **Descompacte o pacote** Extraia o conteúdo do arquivo .zip com o comando:

    unzip script_servidor_linux-main.zip

4. **Dê permissões ao script:** Navegue até o diretório extraído e torne o script menu.sh executável com permissões recursivas usando o comando:

    chmod 777 -R script_servidor_linux-main

5. **Execute o script:** Com permissões de superusuário, execute o script com o comando:

    sudo ./script_servidor_linux-main/menu.sh
    
6. **Siga as instruções:** Siga as orientações apresentadas no menu interativo para completar a instalação e configuração.


**Nota:** Durante a instalação e configuração, siga as instruções cuidadosamente, especialmente ao configurar o MariaDB, onde você será guiado através de um script, atenção o script ao ser executado a opçao de instalação e e configuração do apache e banco de dados ira remover todas as configurações e instalações anteriores.


## Opções do Menu

- **Executar script de instalação e configuração do apache e mariaDb**: Inicializa o script `linux_config.sh` para instalação e configuração dos componentes.
- **Listar arquivos no diretório atual**: Mostra os arquivos presentes no diretório atual.
- **Mostrar o uso do disco**: Informa a utilização atual do espaço em disco.
- **Configurar painel admin do banco de dados**: Configura o acesso ao Adminer movendo `admin.php` para `/var/www/html/` e ajustando suas permissões.
- **Instalar e configurar o servidor DNS**: Inicializa o script `dns_install.sh` para instalação e configuração do servidor DNS.
- **Mudar e configurar versão do PHP**: Inicializa o script `config_php.sh` para alterar e configurar a versão do PHP.
- **Sair**: Termina a execução do menu.

## Licença

Este projeto é distribuído sob a Licença MIT. Para mais detalhes, veja o arquivo `LICENSE`.

## Segurança

As configurações iniciais usam credenciais padrão, que devem ser alteradas para garantir a segurança do ambiente. É recomendado não utilizar permissões `777` em ambientes de produção para arquivos críticos.
