# AMPARO SUS — Global Solution 2026/2

**FIAP | Análise e Desenvolvimento de Sistemas | DevOps Tools & Cloud Computing**
**Tema da Global Solution:** CitizenTech — tecnologia voltada às necessidades das pessoas
**Turma:** 2TDSPA

### Integrantes do grupo

| Integrante | RM |
|---|---|
| Denise Santos | 567559 |
| Karen Cardoso | 566870 |
| Lucas Dudena | 567600 |
| Pedro Begali | 567478 |


## Sobre o nosso projeto

O AMPARO SUS nasceu da ideia de facilitar o registro de pedidos de apoio feitos por pessoas idosas. Pensamos nesse público porque nem sempre é simples buscar uma informação, pedir uma orientação ou acompanhar uma solicitação.

Para esta entrega, desenvolvemos a parte de **API e banco de dados**, e depois montamos o ambiente de **DevOps** para executar os dois serviços em contêineres Docker. Também repetimos a implantação em uma máquina virtual Ubuntu na Microsoft Azure, criada com comandos do Azure CLI.

Nossa API, feita em **C# com ASP.NET Core 8**, permite cadastrar pessoas idosas e registrar solicitações ligadas a esses cadastros. Os dados ficam guardados no **Oracle Database Free**.

É importante explicar o limite do que foi entregue: **esta é uma aplicação acadêmica de demonstração, com dados fictícios**. Não realizamos integração real com os serviços oficiais do SUS. Também não implantamos aplicativo mobile, inteligência artificial ou dispositivos IoT neste ambiente de DevOps.

### O que conseguimos demonstrar

- Os dois contêineres funcionando: **API .NET 8** e **Oracle**.
- As duas tabelas relacionadas: `AMP_IDOSOS` e `AMP_SOLICITACOES`.
- As operações de cadastro, consulta, alteração e exclusão (**CRUD**) das duas entidades, testadas pelo **Thunder Client** no Docker local.
- A gravação dos dados no Oracle, conferida com comandos `SELECT`.
- A preservação dos dados após remover e recriar os contêineres **no ambiente local**, usando um volume nomeado.
- A criação da VM na Azure por **Azure CLI**, a instalação do Docker e a execução dos dois contêineres na VM.
- Na Azure: consultas e cadastros pela API, além de um `INNER JOIN` executado diretamente no Oracle, confirmando o relacionamento das tabelas.

> **Como usar este README:** siga a ordem das etapas. Os comandos indicam onde devem ser executados: no **PowerShell do Windows**, no terminal **Ubuntu da VM** ou no prompt **SQL>** do Oracle. Não é necessário executar comandos no ambiente Azure para testar primeiro no computador local.

---

## 1. Entendendo as ferramentas antes de começar

| Ferramenta | Para que usamos |
|---|---|
| **VS Code** | Abrir e organizar os arquivos do projeto. |
| **C# / ASP.NET Core 8** | Programar a API, ou seja, a parte que recebe pedidos como GET e POST. |
| **Entity Framework Core** | Fazer a comunicação entre as classes C# e as tabelas do Oracle. |
| **Oracle Database Free** | Armazenar os cadastros de idosos e as solicitações. |
| **Dockerfile** | Definir como o Docker monta a imagem da nossa API. |
| **Docker Compose** | Iniciar e conectar a API e o banco sem precisar configurar cada contêiner manualmente toda vez. |
| **Thunder Client** | Enviar requisições para testar o CRUD, diretamente pelo VS Code. |
| **SQL Developer / SQL*Plus** | Consultar as tabelas e confirmar se os dados foram gravados. |
| **Azure CLI** | Criar e consultar os recursos da Azure por comandos. |
| **VM Ubuntu na Azure** | Executar o projeto na nuvem, e não apenas no nosso computador. |

### Como os serviços se comunicam

A requisição chega à **API .NET 8**. O controller recebe os dados, faz as validações e usa o Entity Framework Core para consultar ou alterar o banco Oracle. A API devolve uma resposta em JSON, acompanhada de um status HTTP, como `200 OK` ou `201 Created`.

No Docker Compose utilizamos:

- `amparo-api`: contêiner da API, na porta interna **8080**;
- `amparo-oracle`: contêiner do banco Oracle, com serviço `FREEPDB1` e porta interna **1521**;
- `amparo_net`: rede interna pela qual os dois serviços conversam;
- `oracle_data`: volume nomeado onde ficam os arquivos do banco;
- variáveis de ambiente: informam senhas e configurações sem deixá-las escritas no código-fonte.

A API é executada pelo usuário `app`, que não é administrador do contêiner, e usa o diretório de trabalho `/app`.

**Nosso diagrama editável:** [`docs/ARQUITETURA/AMPARO_SUS_Arquitetura_DevOps.drawio`](docs/ARQUITETURA/AMPARO_SUS_Arquitetura_DevOps.drawio). O diagrama mostra a arquitetura e o fluxo de implantação; não representa integrações que não fizemos.

---

## 2. Onde está cada parte do projeto

```text
AMPARO_SUS_DEVOPS/
│
├── AmparoSus.Api/
│   ├── Controllers/         -> endpoints de idosos e solicitações
│   ├── DTOs/                -> dados de entrada e de resposta da API
│   ├── Data/                -> configuração do acesso ao Oracle
│   ├── Models/              -> classes que representam as entidades
│   ├── Migrations/          -> criação das tabelas pelo Entity Framework
│   ├── Program.cs           -> configuração e inicialização da API
│   └── AmparoSus.Api.csproj -> definição do projeto .NET 8
│
├── docs/
│   ├── ARQUITETURA/         -> diagrama editável do Draw.io
│   └── EVIDENCIAS/          -> prints e relatório de comprovação
│
├── Dockerfile               -> instruções para construir a API
├── docker-compose.yml       -> configuração dos dois contêineres
├── .dockerignore            -> arquivos que não entram na imagem
├── .gitignore               -> arquivos locais que não vão ao GitHub
└── README.md                -> este manual
```

Os arquivos `.env` e `appsettings.json` locais não são enviados ao GitHub porque podem conter informações sensíveis. Vamos criar as configurações necessárias durante o passo a passo.

---

# PARTE A — EXECUTAR NO NOSSO COMPUTADOR

## 3. O que instalar antes de rodar

No Windows, precisamos de:

1. **Git**, para baixar o código do GitHub.
2. **Docker Desktop**, para executar a API e o Oracle em contêineres.
3. **.NET SDK 8**, para aplicar a estrutura das tabelas (*migrations*).
4. **VS Code**, com a extensão **Thunder Client**, para os testes de API.
5. **SQL Developer**, se quiser uma interface visual para consultar o banco (também mostramos uma forma de consultar pelo terminal).

Abra o **PowerShell** e confirme as instalações:

```powershell
git --version
docker --version
docker compose version
dotnet --version
```

Esses comandos só consultam as versões. Se algum deles não funcionar, a ferramenta correspondente precisa ser instalada antes de continuar. O **Docker Desktop deve estar aberto**.

### Baixar o projeto

No terminal, vá à pasta em que deseja guardar o trabalho e execute:

```powershell
git clone https://github.com/Denise-ss/AMPARO_SUS_DEVOPS.git
cd AMPARO_SUS_DEVOPS
```

Substitua `URL_DO_REPOSITORIO_PUBLICO` pelo link do GitHub da entrega. O primeiro comando baixa os arquivos; o segundo entra na pasta do projeto. **Não digite literalmente o texto `URL_DO_REPOSITORIO_PUBLICO`**.

Se você já tem a pasta `AMPARO_SUS_DEVOPS` no computador, não precisa clonar outra vez: basta abri-la no VS Code e continuar.

## 4. Criar o arquivo de senhas (.env)

Na **raiz** do projeto, ao lado do `docker-compose.yml`, crie um arquivo chamado exatamente **`.env`**. Coloque nele:

```dotenv
ORACLE_PWD=ESCOLHA_UMA_SENHA_PARA_O_ADMINISTRADOR
AMPARO_DB_PWD=ESCOLHA_UMA_SENHA_PARA_A_APLICACAO
```

Troque os textos após `=` por **senhas novas**, escolhidas para essa instalação. Não use essas palavras como senhas de verdade.

**Qual é a diferença?**

- `ORACLE_PWD` define a senha administrativa usada na primeira configuração do Oracle.
- `AMPARO_DB_PWD` será a senha do usuário `AMPARO_SUS`, criado para a nossa aplicação. **Ela deve ser a mesma senha informada na etapa de criação desse usuário.**

Para simplificar a reprodução no laboratório, evite caracteres que precisem de interpretação especial no SQL*Plus (por exemplo, aspas duplas e `&`). Não publique o `.env`, não mostre as senhas no vídeo e não copie o conteúdo desse arquivo para o README.

Agora confira se o Compose reconhece as configurações:

```powershell
docker compose config --quiet
```

Se o comando terminar sem mensagens de erro, o Compose conseguiu ler a configuração. Usamos `--quiet` para não exibir as senhas na tela.

## 5. Iniciar primeiro o contêiner Oracle

Ainda no PowerShell, dentro de `AMPARO_SUS_DEVOPS`, execute:

```powershell
docker compose up -d oracle
```

O Compose vai baixar a imagem do Oracle, se ela não estiver no computador, criar o contêiner e iniciar o serviço em segundo plano. O `-d` significa que o terminal fica livre para outros comandos.

Veja como ele está:

```powershell
docker compose ps
docker compose logs --tail=30 oracle
```

No `ps`, procure pelo serviço `oracle` / contêiner `amparo-oracle`. Aguarde até aparecer **Healthy**, indicando que o banco terminou de iniciar. O Oracle pode levar algum tempo na primeira execução.

## 6. Criar o espaço e o usuário da aplicação no Oracle

Essa preparação é importante porque a nossa API não acessa o banco como administrador. Criamos um usuário próprio chamado `AMPARO_SUS`.

No **PowerShell**, entre no SQL*Plus dentro do contêiner:

```powershell
docker compose exec oracle sqlplus "/ as sysdba"
```

A tela deve passar a mostrar `SQL>`. **A partir daqui, os comandos são digitados depois de `SQL>`**, e não no PowerShell.

**Passo 6.1 — Entrar no banco da aplicação:**

```sql
ALTER SESSION SET CONTAINER=FREEPDB1;
```

O Oracle Free utiliza o serviço `FREEPDB1` para os dados da aplicação.

**Passo 6.2 — Criar o tablespace:**

```sql
CREATE TABLESPACE AMPARO_DATA
DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/amparo_data01.dbf'
SIZE 100M AUTOEXTEND ON NEXT 20M MAXSIZE 500M;
```

*Tablespace* é o espaço lógico do Oracle que vai armazenar as tabelas. Nesse projeto demos o nome `AMPARO_DATA`.

**Passo 6.3 — Pedir a senha sem mostrá-la na tela:**

```sql
SET VERIFY OFF
ACCEPT senha CHAR PROMPT 'Senha escolhida em AMPARO_DB_PWD: ' HIDE
```

Digite a **mesma senha** que você colocou na linha `AMPARO_DB_PWD` do `.env`. A digitação fica oculta.

**Passo 6.4 — Criar o usuário:**

```sql
CREATE USER AMPARO_SUS IDENTIFIED BY "&senha"
DEFAULT TABLESPACE AMPARO_DATA
QUOTA 100M ON AMPARO_DATA;
UNDEFINE senha
```

**Passo 6.5 — Permitir que a aplicação se conecte e crie as tabelas:**

```sql
GRANT CREATE SESSION, CREATE TABLE, CREATE SEQUENCE TO AMPARO_SUS;
```

**Passo 6.6 — Conferir:**

```sql
SELECT USERNAME, ACCOUNT_STATUS, DEFAULT_TABLESPACE
FROM DBA_USERS
WHERE USERNAME = 'AMPARO_SUS';
```

Esperamos encontrar `AMPARO_SUS`, situação `OPEN` e tablespace `AMPARO_DATA`.

Digite `EXIT` para sair do SQL*Plus.

> Se o tablespace ou usuário já existir, não repita os comandos `CREATE` automaticamente. Pode ser que a instalação anterior ainda esteja guardada no volume. Nesse caso, confira o banco antes de fazer mudanças.

## 7. Criar as tabelas com as migrations

Agora o banco está ligado e o usuário está criado, mas precisamos criar as tabelas da API. Nós fizemos isso com o **Entity Framework Core**.

No **PowerShell do Windows**, dentro da pasta do projeto, confira a ferramenta:

```powershell
dotnet ef --version
```

Se aparecer a mensagem de que `dotnet ef` não existe, instale a versão que utilizamos no projeto:

```powershell
dotnet tool install --global dotnet-ef --version 8.0.34
```

O comando instala a ferramenta para criar e atualizar estruturas de banco pelo Entity Framework.

### Informar a conexão do Oracle sem escrever a senha no código

No **PowerShell**, execute:

```powershell
$senha = Read-Host 'Digite a senha do usuario AMPARO_SUS' -AsSecureString
$cred = [PSCredential]::new('AMPARO_SUS', $senha)
$env:ConnectionStrings__Oracle = "User Id=AMPARO_SUS;Password=$($cred.GetNetworkCredential().Password);Data Source=localhost:1521/FREEPDB1;"
```

- `Read-Host -AsSecureString` pede a senha sem exibi-la.
- `ConnectionStrings__Oracle` é a configuração lida pelo `Program.cs`.
- `localhost:1521/FREEPDB1` indica o Oracle que está rodando no Docker **deste computador**.

### Aplicar a migration

```powershell
dotnet ef database update --project .\AmparoSus.Api\AmparoSus.Api.csproj --startup-project .\AmparoSus.Api\AmparoSus.Api.csproj --context AmparoSusDbContext
```

Esse comando lê a migration `InicialAmparoSus`, já existente na pasta `Migrations`, e prepara as tabelas `AMP_IDOSOS` e `AMP_SOLICITACOES`.

Na primeira execução, procure uma mensagem parecida com `Applying migration ... InicialAmparoSus` e, ao final, `Done`. Se a migration já tiver sido aplicada, a ferramenta pode informar que o banco está atualizado.

Depois retire a conexão temporária do terminal:

```powershell
Remove-Item Env:\ConnectionStrings__Oracle
```

Isso limpa a configuração da sessão do PowerShell. Não altera o `.env`.

## 8. Subir a API e verificar a comunicação com o Oracle

Agora podemos iniciar os dois serviços juntos:

```powershell
docker compose up -d --build
docker compose ps
```

O `--build` faz o Docker construir a API com o `Dockerfile`. O banco Oracle será reutilizado. No `ps`, procure os contêineres **`amparo-api`** e **`amparo-oracle`**.

Teste no navegador:

- `http://localhost:8080/` — apresenta o nome do projeto e suas rotas;
- `http://localhost:8080/api/idosos` — lista os idosos cadastrados;
- `http://localhost:8080/api/solicitacoes` — lista as solicitações.

Se aparecer `[]` com resposta **HTTP 200 OK**, não é erro: significa que a consulta funcionou, mas ainda não existem registros nessa instalação.

Se a API não responder, consulte as mensagens:

```powershell
docker compose logs --tail=50 api
docker compose logs --tail=50 oracle
```

**Um erro que encontramos durante os testes na Azure foi `ORA-01017`.** Ele acontece quando a senha de conexão informada à API não corresponde à senha do usuário no Oracle. Alterar apenas o `.env` não altera uma senha já cadastrada no banco.

---

# PARTE B — TESTANDO O CADASTRO COM O THUNDER CLIENT

## 9. O que significa CRUD e como testar

CRUD é o nome dado às quatro operações básicas de um cadastro:

| Sigla | Método HTTP | O que fazemos |
|---|---|---|
| Create | `POST` | Criar um registro novo. |
| Read | `GET` | Consultar um ou vários registros. |
| Update | `PUT` | Alterar um registro existente. |
| Delete | `DELETE` | Apagar um registro. |

Testamos essas operações usando a extensão **Thunder Client** no VS Code. Não construímos uma tela de formulário para essa entrega: o Thunder Client foi nossa ferramenta para enviar os dados à API e analisar as respostas.

**Como abrir:** VS Code → Thunder Client → **New Request**. Selecione o método (GET/POST/PUT/DELETE), informe o endereço e clique em **Send**. Para `POST` e `PUT`, abra **Body → JSON** e cole o exemplo correspondente.

### 9.1 Cadastrar e consultar uma pessoa idosa

**Criar — POST** `http://localhost:8080/api/idosos`

```json
{
  "nome": "Maria da Silva",
  "telefone": "11988887777",
  "cidade": "Campinas"
}
```

A API deve responder com **201 Created** e mostrar o novo registro com um **ID**. Anote o número retornado, pois ele pode ser diferente de `1` no seu computador.

**Consultar todos — GET** `http://localhost:8080/api/idosos`

A resposta deve mostrar uma lista com os registros existentes.

**Consultar um — GET** `http://localhost:8080/api/idosos/ID`

Troque `ID` pelo número retornado no POST. O resultado esperado é **200 OK** com o cadastro escolhido.

**Atualizar — PUT** `http://localhost:8080/api/idosos/ID`

Para alterar o cadastro, envie no **Body → JSON** os novos dados:

```json
{
  "nome": "Maria da Silva",
  "telefone": "11988887777",
  "cidade": "Sao Paulo"
}
```

É um exemplo de atualização da cidade. A API deve retornar **204 No Content**. Esse status significa que a alteração foi aceita e não há conteúdo para apresentar na resposta. Depois faça outro GET para conferir os dados atualizados.

**Excluir — DELETE** `http://localhost:8080/api/idosos/ID`

Só faça esse teste com um cadastro fictício que você **não vai usar nas solicitações**. O resultado esperado é **204 No Content**. Depois consulte pelo mesmo ID: a API deve indicar que o registro não foi encontrado, normalmente **404 Not Found**.

> **Cuidado com a ordem:** para demonstrar o relacionamento entre tabelas, mantenha ao menos um idoso cadastrado. Se você apagar o cadastro antes de criar a solicitação, não terá um ID válido para vincular.

### 9.2 Cadastrar e consultar uma solicitação de apoio

Primeiro, tenha um idoso cadastrado e use o **ID que sua API devolveu**.

**Criar — POST** `http://localhost:8080/api/solicitacoes`

```json
{
  "idosoId": 1,
  "tipo": "ORIENTACAO",
  "descricao": "Solicito orientacao sobre agendamento de consulta na unidade de saude.",
  "status": "PENDENTE"
}
```

No exemplo, `idosoId: 1` aponta para o idoso de ID `1`. **Substitua esse número se o ID criado no seu banco for outro.** A API deve retornar **201 Created**, com o ID da solicitação.

Os tipos aceitos pelo nosso projeto são `ORIENTACAO`, `ACOMPANHAMENTO` e `VISITA`. Os status são `PENDENTE`, `EM_ATENDIMENTO` e `CONCLUIDA`.

**Consultar todas — GET** `http://localhost:8080/api/solicitacoes`

**Consultar uma — GET** `http://localhost:8080/api/solicitacoes/ID_DA_SOLICITACAO`

A resposta de uma solicitação existente deve ser **200 OK**.

**Atualizar — PUT** `http://localhost:8080/api/solicitacoes/ID_DA_SOLICITACAO`

```json
{
  "idosoId": 1,
  "tipo": "ORIENTACAO",
  "descricao": "A solicitacao esta sendo acompanhada pela equipe.",
  "status": "EM_ATENDIMENTO"
}
```

Troque também o `idosoId` pelo valor que existe no seu banco. O esperado é **204 No Content**. Faça um GET para verificar se o status mudou.

Se quiser demonstrar a conclusão, repita o PUT com `"status": "CONCLUIDA"` e uma descrição correspondente ao pedido finalizado. Foi assim que testamos a mudança de situação na etapa local.

**Excluir — DELETE** `http://localhost:8080/api/solicitacoes/ID_DA_SOLICITACAO`

O esperado é **204 No Content**. Um GET do mesmo ID deve indicar ausência do registro. Depois, consultar o idoso permite conferir que o cadastro dele continua salvo.

### 9.3 Um lembrete sobre os testes que realizamos

Fizemos o **CRUD completo** das duas entidades no **Docker local**, com capturas no Thunder Client e verificações no Oracle. Na **Azure**, repetimos os testes principais: GET e POST de idoso, POST de solicitação e consulta de relacionamento no banco. Mantivemos essa distinção para o relatório mostrar exatamente o que foi feito.

---

# PARTE C — CONFERIR O BANCO E O DOCKER

## 10. Consultar os dados diretamente no Oracle

Usamos o **Oracle SQL Developer** para visualizar as tabelas e seus registros. Em uma instalação local, a conexão pode ser configurada com:

| Campo | Valor |
|---|---|
| Usuário | `AMPARO_SUS` |
| Senha | A mesma escolhida em `AMPARO_DB_PWD` |
| Host | `localhost` |
| Porta | `1521` |
| Serviço | `FREEPDB1` |

Também é possível abrir o SQL*Plus pelo terminal:

```powershell
docker compose exec oracle sqlplus "/ as sysdba"
```

No prompt `SQL>`, selecione o banco da aplicação:

```sql
ALTER SESSION SET CONTAINER=FREEPDB1;
```

**Consultar os cadastros de idosos:**

```sql
SELECT ID, NOME, TELEFONE, CIDADE
FROM AMPARO_SUS.AMP_IDOSOS;
```

**Consultar as solicitações:**

```sql
SELECT ID, IDOSO_ID, TIPO, DESCRICAO, STATUS
FROM AMPARO_SUS.AMP_SOLICITACOES;
```

**Conferir o relacionamento entre as duas tabelas:**

```sql
SELECT
    I.ID AS ID_IDOSO,
    I.NOME AS NOME_IDOSO,
    S.ID AS ID_SOLICITACAO,
    S.TIPO,
    S.STATUS
FROM AMPARO_SUS.AMP_IDOSOS I
INNER JOIN AMPARO_SUS.AMP_SOLICITACOES S
    ON I.ID = S.IDOSO_ID;
```

O `INNER JOIN` junta as informações que possuem um ID relacionado. Se houver uma solicitação cadastrada, a consulta mostrará o nome do idoso junto com os dados do pedido. Se a tabela de solicitações estiver vazia, o JOIN também retornará vazio.

Depois de consultar, digite `EXIT` para sair do SQL*Plus.

## 11. Conferir rede, logs, acesso aos contêineres e usuário

Estes comandos são executados no **PowerShell**, na raiz do projeto:

```powershell
docker compose ps
```

Mostra os serviços e confirma se estão executando em segundo plano.

```powershell
docker compose logs --tail=30 api
docker compose logs --tail=30 oracle
```

Mostram as últimas 30 linhas de mensagens da API e do Oracle. Foi dessa forma que conferimos a inicialização e encontramos erros de conexão durante o desenvolvimento.

```powershell
docker compose exec -T api id
```

Entra no contêiner para executar o comando `id`, que identifica o usuário. Na nossa imagem, o retorno foi `uid=1654(app)`, comprovando que não é o usuário root.

```powershell
docker compose exec -T api pwd
```

O comando `pwd` mostra em qual diretório a API está trabalhando. O resultado que obtivemos foi `/app`, conforme o `WORKDIR` do Dockerfile.

```powershell
docker compose exec -T api ls /app
```

Lista arquivos no diretório da API. É um exemplo de como acessar e conferir o conteúdo do contêiner.

```powershell
docker network ls
docker volume ls
```

O primeiro comando lista as redes Docker; o segundo, os volumes. Procure a rede do projeto (terminada em `amparo_net`) e o volume terminado em `oracle_data`. O Docker Compose costuma acrescentar o nome da pasta do projeto no início desses nomes.

Para inspecionar a rede ou o volume com mais detalhes, use o nome mostrado nos comandos anteriores:

```powershell
docker network inspect NOME_DA_REDE
docker volume inspect NOME_DO_VOLUME
```

Substitua `NOME_DA_REDE` e `NOME_DO_VOLUME` pelos nomes reais que aparecerem na sua instalação.

## 12. Demonstrar a persistência dos dados

Uma das exigências era comprovar que o Oracle não perde o cadastro quando o contêiner é recriado.

**Primeiro**, cadastre um idoso fictício com o Thunder Client e faça um GET para confirmar que o cadastro existe. Guarde o número do ID.

Depois, no PowerShell:

```powershell
docker compose down
```

Esse comando remove os contêineres e a rede configurados pelo Compose, mas **não remove o volume nomeado**.

Agora recrie os serviços:

```powershell
docker compose up -d
docker compose ps
```

Aguarde o Oracle ficar saudável, faça novamente o GET ou SELECT do cadastro anterior e confira se ele continua no banco. **Foi esse teste que realizamos no Docker local**.

**Não use `docker compose down -v` para testar persistência.** O `-v` pede para remover os volumes, incluindo o espaço em que o Oracle grava os dados.

---

# PARTE D — IMPLANTAÇÃO NA MICROSOFT AZURE

## 13. O que fizemos na nuvem

Depois de validar a API e o banco localmente, criamos uma **máquina virtual Ubuntu na Azure** utilizando o Azure CLI. Instalamos o Docker nessa VM, enviamos os arquivos necessários com `tar` e `scp` e iniciamos os mesmos serviços do Docker Compose.

Para acessar a API e o banco com segurança, usamos **túneis SSH**. Assim, a API estava rodando na Azure, mas podíamos testá-la pelo Thunder Client no nosso computador sem abrir a porta 8080 para toda a internet. A porta do Oracle também não foi publicada na internet.

### Antes de executar na Azure

É necessário ter **Azure CLI instalado**, uma **assinatura Azure autorizada a criar VMs** e créditos ou recursos disponíveis. **Criar uma VM pode gerar cobranças**. Os nomes usados abaixo são os nomes que utilizamos na entrega. Se os recursos já existirem na assinatura, não crie outros com os mesmos nomes sem conferir.

## 14. Criar o grupo de recursos e a VM com Azure CLI

No **PowerShell do Windows**:

```powershell
az login
az account show --output table
```

O primeiro comando permite entrar na conta Azure; o segundo mostra a assinatura que será usada. Confirme se é a assinatura correta antes de criar recursos.

**Criar o grupo de recursos:**

```powershell
az group create --name rg-amparo-sus-devops --location mexicocentral --output table
```

O grupo reúne os recursos do AMPARO SUS. Usamos a região `mexicocentral`.

**Criar a VM Ubuntu (configuração usada na nossa demonstração):**

```powershell
az vm create --resource-group rg-amparo-sus-devops --name vm-amparo-sus --location mexicocentral --zone 1 --image Ubuntu2204 --size Standard_B2as_v2 --admin-username azureuser --generate-ssh-keys --os-disk-size-gb 64 --storage-sku StandardSSD_LRS --public-ip-sku Standard --nsg-rule SSH --output table
```

Nesse comando:

- `--resource-group` indica em qual grupo a VM será criada;
- `--name` define o nome da máquina;
- `--image Ubuntu2204` instala o Ubuntu 22.04;
- `--size` define o tamanho da VM;
- `--generate-ssh-keys` permite o acesso por chave SSH;
- `--nsg-rule SSH` libera o acesso necessário para entrar na VM por SSH.

**Como conferir o resultado:**

```powershell
az vm show -d --resource-group rg-amparo-sus-devops --name vm-amparo-sus --query "{nome:name,estado:powerState,ip:publicIps}" --output table
```

A VM deve aparecer como `VM running`. Dependendo da assinatura Azure, a zona ou o tamanho da máquina podem não estar disponíveis. Nesse caso, é preciso escolher opções permitidas pela assinatura, registrando a mudança feita.

## 15. Conectar na VM e instalar Docker

Ainda no **PowerShell do Windows**, obtenha o IP atual da VM:

```powershell
$ip = az vm show -d --resource-group rg-amparo-sus-devops --name vm-amparo-sus --query publicIps -o tsv
```

Esse comando guarda o IP na variável `$ip`. Preferimos consultar o IP porque ele pode mudar se a VM for desalocada e iniciada novamente.

**Acessar por SSH:**

```powershell
ssh -i "$HOME\.ssh\id_rsa" "azureuser@${ip}"
```

O nome `azureuser` é o usuário que criamos na VM. O caminho da chave SSH corresponde à chave utilizada na nossa demonstração; em outro computador, use o caminho da chave criada pelo Azure CLI. No primeiro acesso, confirme a identidade do servidor antes de aceitar sua chave de host.

**Os próximos comandos são executados dentro da VM Ubuntu**, depois que aparecer o terminal `azureuser@vm-amparo-sus`:

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo docker --version
sudo docker compose version
```

Baixamos o script de instalação do Docker, executamos a instalação e consultamos as versões. Na VM utilizamos **`sudo docker`**, pois o usuário de acesso não foi configurado para executar o Docker sem privilégios administrativos.

## 16. Enviar os arquivos para a VM (tar + scp)

Nossa implantação não foi automática pelo GitHub. **Nós empacotamos o código no Windows e o enviamos para a VM usando SSH.** O GitHub é utilizado para entregar o código e as instruções ao professor.

Volte a um terminal **PowerShell do Windows**, na pasta `AMPARO_SUS_DEVOPS`. Se precisar, obtenha o IP novamente com o comando da etapa 15.

**Montar o pacote com os arquivos necessários:**

```powershell
tar -czf amparo-sus-deploy.tar.gz Dockerfile docker-compose.yml .dockerignore AmparoSus.Api/AmparoSus.Api.csproj AmparoSus.Api/Program.cs AmparoSus.Api/Controllers AmparoSus.Api/Data AmparoSus.Api/DTOs AmparoSus.Api/Migrations AmparoSus.Api/Models
```

O `tar` junta esses arquivos em um pacote `.tar.gz`. **Não incluímos o `.env` nem arquivos com senhas.**

**Enviar o pacote pela conexão SSH:**

```powershell
scp -i "$HOME\.ssh\id_rsa" .\amparo-sus-deploy.tar.gz "azureuser@${ip}:~/"
```

O `scp` copia o pacote para a pasta pessoal do usuário na VM.

**Na VM Ubuntu**, organize os arquivos:

```bash
mkdir -p ~/amparo-sus
tar -xzf ~/amparo-sus-deploy.tar.gz -C ~/amparo-sus
cd ~/amparo-sus
ls -la
```

O `ls -la` deve mostrar `Dockerfile`, `docker-compose.yml`, `.dockerignore` e a pasta `AmparoSus.Api`.

> Se você estiver reproduzindo o trabalho a partir do GitHub, também pode baixar o repositório público e seguir as etapas de configuração da VM. O procedimento documentado acima, com `tar` e `scp`, é o que efetivamente utilizamos.

## 17. Preparar o Oracle dentro da VM

Na VM, na pasta `~/amparo-sus`, crie um `.env` próprio:

```bash
nano .env
```

Dentro desse arquivo coloque `ORACLE_PWD` e `AMPARO_DB_PWD` com **senhas novas** escolhidas para a VM, seguindo a explicação da etapa 4. Salve e feche o editor. **Não grave nem mostre o conteúdo desse arquivo em um vídeo público.**

Proteja o arquivo e inicie o Oracle:

```bash
chmod 600 .env
sudo docker compose config --quiet
sudo docker compose up -d oracle
sudo docker compose ps
```

- `chmod 600` restringe a leitura e escrita do `.env` ao proprietário;
- `config --quiet` verifica a configuração sem mostrar as senhas;
- `up -d oracle` inicia somente o banco.

**Agora repita o preparo do Oracle da etapa 6**, mudando apenas o comando de entrada no SQL*Plus para:

```bash
sudo docker compose exec oracle sqlplus "/ as sysdba"
```

Crie o tablespace `AMPARO_DATA`, o usuário `AMPARO_SUS`, as permissões e confira se ele está `OPEN`. Use no `CREATE USER` **exatamente a senha escolhida em `AMPARO_DB_PWD` da VM**.

## 18. Aplicar as migrations no Oracle da Azure

Para criar as duas tabelas **no Oracle da VM**, utilizamos o .NET instalado no Windows e um túnel SSH até o banco.

**No primeiro PowerShell do Windows**, execute:

```powershell
$ip = az vm show -d --resource-group rg-amparo-sus-devops --name vm-amparo-sus --query publicIps -o tsv
ssh -i "$HOME\.ssh\id_rsa" -o ExitOnForwardFailure=yes -N -L 127.0.0.1:11521:127.0.0.1:1521 "azureuser@${ip}"
```

Esse terminal **fica ocupado** enquanto o túnel estiver aberto. É esperado: ele está conectando a porta `11521` do Windows à porta `1521` do Oracle na Azure. Não feche esse terminal até terminar de aplicar a migration.

**Em outro PowerShell do Windows**, entre na pasta do projeto e informe a conexão:

```powershell
$senha = Read-Host 'Senha AMPARO_SUS do Oracle na Azure' -AsSecureString
$cred = [PSCredential]::new('AMPARO_SUS', $senha)
$env:ConnectionStrings__Oracle = "User Id=AMPARO_SUS;Password=$($cred.GetNetworkCredential().Password);Data Source=localhost:11521/FREEPDB1;"
```

Veja que usamos **`11521`** aqui. É a porta do túnel SSH, não a porta `1521` do Oracle local.

**Aplicar a migration na Azure:**

```powershell
dotnet ef database update --project .\AmparoSus.Api\AmparoSus.Api.csproj --startup-project .\AmparoSus.Api\AmparoSus.Api.csproj --context AmparoSusDbContext
```

Espere a mensagem de conclusão `Done`. Depois limpe a conexão temporária:

```powershell
Remove-Item Env:\ConnectionStrings__Oracle
```

Para encerrar o túnel, volte ao primeiro PowerShell e pressione **Ctrl + C**, mas só depois de confirmar que a migration terminou.

## 19. Subir os dois contêineres na VM e testar

No terminal **Ubuntu da VM**, entre na pasta e execute:

```bash
cd ~/amparo-sus
sudo docker compose up -d --build
sudo docker compose ps
```

O Compose vai construir a imagem da API e iniciar a aplicação junto do Oracle. No resultado, procure `amparo-oracle` saudável e `amparo-api` iniciado.

**Consultar os logs:**

```bash
sudo docker compose logs --tail=30 api
sudo docker compose logs --tail=30 oracle
```

**Testar a API dentro da própria VM:**

```bash
curl -i http://127.0.0.1:8080/api/idosos
```

Se vier **HTTP 200 OK** com `[]`, a comunicação está funcionando e a tabela ainda não recebeu cadastros.

### Acessar a API da Azure pelo Thunder Client

No **PowerShell do Windows**, abra outro túnel:

```powershell
$ip = az vm show -d --resource-group rg-amparo-sus-devops --name vm-amparo-sus --query publicIps -o tsv
ssh -i "$HOME\.ssh\id_rsa" -o ExitOnForwardFailure=yes -N -L 127.0.0.1:18080:127.0.0.1:8080 "azureuser@${ip}"
```

Deixe esse terminal aberto enquanto usa o Thunder Client. A porta `18080` do Windows passa a encaminhar as requisições para a porta `8080` **da VM Azure**, por SSH.

No Thunder Client, use:

- `GET http://localhost:18080/api/idosos`;
- `POST http://localhost:18080/api/idosos` (com o JSON da etapa 9.1);
- `GET http://localhost:18080/api/idosos/ID` (com o ID retornado);
- `POST http://localhost:18080/api/solicitacoes` (com o JSON da etapa 9.2 e o ID correto).

Essas foram as principais chamadas demonstradas na Azure. Para conferir o relacionamento, usamos um `INNER JOIN` no Oracle da própria VM (consulta da etapa 10).

**Por que aparece `localhost` se a API está na Azure?** Porque o túnel SSH cria uma passagem segura até a máquina virtual. Não significa que estamos testando a API local do Windows.

---

# PARTE E — EVIDÊNCIAS, ENTREGA E ENCERRAMENTO

## 20. Onde estão as nossas evidências

Na pasta [`docs/EVIDENCIAS`](docs/EVIDENCIAS) estão os prints que registramos ao longo do trabalho. Também montamos o documento `relatorio_evidencias_AMPARO_SUS_DEVOPS.docx`, com títulos e explicações do que cada teste comprova.

Para facilitar a conferência do professor, separamos as comprovações por assunto:

| O que foi pedido | Onde demonstramos |
|---|---|
| Arquitetura macro | Diagrama Draw.io e `PRINT_01`. |
| API e Dockerfile | `PRINT_02`, `PRINT_03`, `PRINT_04`. |
| Banco Oracle e dois contêineres | `PRINT_05` e `PRINT_07` a `PRINT_13`. |
| CRUD de idosos no Thunder Client | `PRINT_14` a `PRINT_20` e consultas no Oracle. |
| CRUD de solicitações e relacionamento | `PRINT_22` a `PRINT_33`. |
| Volume e persistência após recriação | `PRINT_34` a `PRINT_38`. |
| Rede, logs, usuário não root e WORKDIR | `PRINT_39` a `PRINT_43`. |
| Azure CLI e criação da VM | `PRINT_44`, `PRINT_46`, `PRINT_47` e `PRINT_48`. |
| Docker, banco e API na Azure | `PRINT_49` a `PRINT_54`. |
| Testes pelo Thunder Client na Azure | `PRINT_55` a `PRINT_58`. |
| SELECT com INNER JOIN na Azure | `PRINT_59`. |

A numeração dos prints segue os arquivos disponíveis; nem todos os números possuem uma imagem separada. Não inventamos evidências para preencher lacunas da sequência.

## 21. Sobre o vídeo de demonstração

O vídeo da entrega precisa mostrar **VM na Azure, Docker Compose, os dois contêineres, CRUD, logs e SELECT no banco**, com narração, legendas e resolução de pelo menos **720p**. Nós utilizamos as telas e os resultados reais do desenvolvimento.

Para mostrar o CRUD completo, os registros do Thunder Client no Docker local documentam `GET`, `POST`, `PUT` e `DELETE` das duas entidades. Na Azure, documentamos a VM funcionando, requisições reais à API e a consulta `INNER JOIN` no Oracle. Assim não confundimos testes locais com testes na nuvem.

**Vídeo no YouTube (Não listado):** inserir o link após a publicação.

## 22. Encerramento da infraestrutura Azure (somente depois de salvar as evidências)

A infraestrutura Azure é temporária e pode consumir créditos. Antes de remover recursos, **confirme que todas as gravações, prints, vídeos, arquivos e links já foram salvos**.

No **PowerShell do Windows**, para verificar o que existe no grupo de recursos:

```powershell
az resource list --resource-group rg-amparo-sus-devops --output table
```

Confira se o grupo contém **somente os recursos criados para este trabalho**. Não execute a exclusão se houver algo de outro projeto.

**Se precisar apenas parar o custo de computação, mantendo a VM para depois:**

```powershell
az vm deallocate --resource-group rg-amparo-sus-devops --name vm-amparo-sus
```

Esse comando desaloca a VM, mas não remove todos os custos de armazenamento e outros recursos associados.

**Se a apresentação já estiver documentada e houver autorização para excluir definitivamente os recursos:**

```powershell
az group delete --name rg-amparo-sus-devops --yes
```

**Atenção:** esse comando pede a exclusão de **todo o grupo de recursos e seus itens**. A operação é destrutiva. Para ter certeza de que a exclusão terminou, execute:

```powershell
az group exists --name rg-amparo-sus-devops
```

A resposta deve ser `false`. Salve os prints do comando de exclusão e da confirmação para incluir no relatório e no vídeo.

## 23. Dúvidas comuns durante a execução

**A API respondeu `[]` e 200 OK.** Isso é normal: a tabela está vazia, mas a consulta funcionou.

**O Oracle está como `Starting`.** Confira `docker compose logs --tail=30 oracle` e só prossiga quando ficar saudável.

**O Oracle respondeu `ORA-01017`.** Verifique se a senha do usuário `AMPARO_SUS` no banco é a mesma indicada por `AMPARO_DB_PWD` no `.env`. Mudar o `.env` não troca a senha que já existe no Oracle.

**O POST não cadastrou a solicitação.** Confira se o `idosoId` corresponde a um cadastro existente e se o tipo/status enviados são permitidos.

**O Thunder Client retornou 404.** Confira o endpoint e o ID. Talvez aquele cadastro não exista ou já tenha sido excluído.

**O acesso à Azure não respondeu.** Confirme se a VM está ligada, se os dois contêineres estão em execução e se o túnel SSH está aberto. `localhost:18080` é usado com o túnel; `localhost:8080` é usado para a API local.

**O cadastro sumiu após recriar o contêiner.** Confira se o Compose está usando o volume nomeado correto. Não use `docker compose down -v` se quiser manter os dados.

**O professor não conseguiu repetir os passos.** Releia a ordem: Docker ligado → `.env` → Oracle Healthy → usuário/tablespace → migrations → API → Thunder Client. Se essas etapas estiverem invertidas, a API pode iniciar sem conseguir acessar as tabelas.

---

## Links e arquivos da entrega

**Projeto:** AMPARO SUS — Global Solution 2026/2 (CitizenTech)

**Disciplina:** DevOps Tools & Cloud Computing

**Turma:** 2TDSPA

**Integrantes:**
- Denise Santos — RM 567559
- Karen Cardoso — RM 566870
- Lucas Dudena — RM 567600
- Pedro Begali — RM 567478

### Repositório GitHub

https://github.com/Denise-ss/AMPARO_SUS_DEVOPS

### Vídeo demonstrativo

O vídeo será disponibilizado no YouTube, como não listado, após a gravação e edição, com narração e legendas.

### Arquivos do projeto

- **Código-fonte:** pasta `AmparoSus.Api/`
- **Dockerfile:** `Dockerfile`
- **Docker Compose:** `docker-compose.yml`
- **Arquitetura:** `docs/ARQUITETURA/AMPARO_SUS_Arquitetura_DevOps.drawio`
- **Script Azure CLI:** `scripts/Azure_CLI_Provisionar_VM_AMPARO_SUS.ps1`
- **Evidências técnicas:** pasta `docs/EVIDENCIAS/`
- **Manual de execução:** este `README.md`

### Sobre as evidências

Os testes completos de CRUD foram realizados com o Thunder Client no ambiente Docker local.

Na máquina virtual Azure, também demonstramos o funcionamento dos contêineres, a conexão da API com o Oracle, os cadastros e o relacionamento entre as tabelas.

As evidências apresentam os resultados reais obtidos durante o desenvolvimento e a implantação.