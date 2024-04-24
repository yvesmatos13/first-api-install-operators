OBJETIVO:

Criar a estruruta do RHSSO:

- Instalar Operador
- Criar Instância
- Criar configurações para a POC: Realms, Clients e Usuários


SETUP:

- Necessário alterar as seguintes variáveis no script install-rhsso.sh:

API_SERVER=https://api.cluster-jv6jb.jv6jb.sandbox1932.opentlc.com:6443
USER=admin
PASSWORDD=8ejYZhKTPpAkhvja

- Executar: sh 1-create-rhsso.sh

- Ao final da execução, você terá um projeto com nome rhsso, uma instância do rhsso, com Realms, Clients e Usuários criados para execução de POC de microsserviços