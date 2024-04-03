# Instalador Automatizado de Ambiente de Desenvolvimento

Este script Bash automatiza o processo de instalação e configuração de um ambiente de desenvolvimento no Ubuntu. Ele instala e configura os seguintes componentes:

- Apache
- MySQL
- PHP
- PHPMyAdmin
- Adminer
- SSH
- FTP

## Requisitos

- Ubuntu (testado na versão 18.04 LTS)
- Permissões de superusuário (ou acesso ao sudo)

## Uso

1. Faça o download do script `install.sh`.
2. Torne-o executável com o comando: `chmod +x install.sh`.
3. Execute o script com permissões de superusuário: `sudo ./install.sh`.
4. Siga as instruções apresentadas no menu interativo.

**Nota:** Certifique-se de ter a senha do banco de dados em mãos durante a execução do script. As credenciais padrão são:
- Usuário: admin
- Senha: admin_123

Após a instalação, recomendamos fortemente que você altere essas credenciais por motivos de segurança.

## Licença

Este script é distribuído sob a Licença MIT. Consulte o arquivo [LICENSE](LICENSE) para obter mais detalhes.
