# Sistema de Configuração para Ambiente de Desenvolvimento Linux

Este projeto oferece um sistema automatizado para a configuração de um ambiente de desenvolvimento em Linux, especificamente projetado para Ubuntu. Utiliza uma interface de menu para simplificar a instalação e configuração de componentes essenciais como Apache, PHP, e MariaDB, além de facilitar a manutenção básica do sistema.

## Componentes Instalados

- **Apache**: Servidor web robusto para hospedagem de páginas.
- **PHP**: Linguagem de script do lado do servidor, incluindo várias extensões como `php-mysql`, `php-intl`, e outras.
- **MariaDB**: Sistema de gerenciamento de banco de dados, uma alternativa ao MySQL.
- **Adminer**: Ferramenta de administração de banco de dados em PHP.

## Requisitos

- Ubuntu (testado na versão 18.04 LTS ou superior)
- Permissões de superusuário (sudo)

## Uso

1. Faça o download do script `menu.sh`.
2. Torne-o executável com o comando: `chmod +x menu.sh`.
3. Execute o script com permissões de superusuário: `sudo ./menu.sh`.
4. Siga as instruções apresentadas no menu interativo.

**Nota:** Durante a instalação e configuração, siga as instruções cuidadosamente, especialmente ao configurar o MariaDB, onde você será guiado através de um script, atenção o script ao ser executado a opçao de instalação e e configuração do apache e banco de dados ira remover todas as configurações e instalações anteriores.

## Opções do Menu

- **Executar script de instalação e configuração**: Inicializa o script `linux_config.sh` para instalação e configuração dos componentes.
- **Listar arquivos no diretório atual**: Mostra os arquivos presentes no diretório atual.
- **Mostrar o uso do disco**: Informa a utilização atual do espaço em disco.
- **Configurar painel admin do banco de dados**: Configura o acesso ao Adminer movendo `admin.php` para `/var/www/html/` e ajustando suas permissões.
- **Sair**: Termina a execução do menu.

## Licença

Este projeto é distribuído sob a Licença MIT. Para mais detalhes, veja o arquivo [LICENSE](LICENSE).

## Segurança

As configurações iniciais usam credenciais padrão, que devem ser alteradas para garantir a segurança do ambiente. É recomendado não utilizar permissões `777` em ambientes de produção para arquivos críticos.
