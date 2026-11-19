# GLOBAL SOLUTION 2026/2 - AMPARO SUS
# DevOps Tools & Cloud Computing | FIAP | Turma 2TDSPA
#
# Este script registra os comandos do Azure CLI que usamos para
# criar o grupo de recursos e a maquina virtual Ubuntu do projeto.
# Execute no PowerShell do Windows, com o Azure CLI instalado.
# ATENCAO: criar recursos na Azure pode gerar cobrancas.
# Este arquivo NAO instala o Docker ou publica a API.
# Esses passos estao explicados no README.md.

# 1) Entrar na Azure. Uma janela do navegador pode ser aberta.
az login
if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel entrar na Azure.' }

# 2) Conferir a assinatura selecionada.
# Antes de continuar, confirme que esta na conta certa.
az account show --output table
if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel consultar a assinatura.' }
$confirmacao = Read-Host 'A assinatura exibida esta correta? Digite SIM para continuar'
if ($confirmacao -cne 'SIM') { Write-Host 'Execucao cancelada sem criar recursos.'; exit }

# 3) Definir os nomes e as configuracoes utilizadas na entrega.
$grupo = 'rg-amparo-sus-devops'
$vm = 'vm-amparo-sus'
$regiao = 'mexicocentral'

# 4) Criar o grupo de recursos (ou confirmar o grupo existente).
# O grupo e como uma pasta que organiza os recursos na Azure.
az group create --name $grupo --location $regiao --output table
if ($LASTEXITCODE -ne 0) { throw 'Falha ao criar/consultar o grupo de recursos.' }

# 5) Evitar criar por engano uma segunda VM com o mesmo nome.
$vmExistente = az vm show --resource-group $grupo --name $vm --query id --output tsv 2>$null
if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($vmExistente)) {
    Write-Host 'A VM ja existe. Nao e necessario cria-la novamente.'
} else {
    # 6) Criar a VM Ubuntu 22.04 usando os parametros do nosso projeto.
    # A opcao --generate-ssh-keys gera/reutiliza uma chave SSH local.
    # A opcao --nsg-rule SSH libera a conexao SSH na VM.
    az vm create `
      --resource-group $grupo `
      --name $vm `
      --location $regiao `
      --zone 1 `
      --image Ubuntu2204 `
      --size Standard_B2as_v2 `
      --admin-username azureuser `
      --generate-ssh-keys `
      --os-disk-size-gb 64 `
      --storage-sku StandardSSD_LRS `
      --public-ip-sku Standard `
      --nsg-rule SSH `
      --output table
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao criar a maquina virtual. Confira a cota e o tamanho disponivel na sua assinatura.' }
}

# 7) Conferir o estado final da VM e o IP de acesso.
# Esperamos visualizar 'VM running' quando a VM estiver ligada.
az vm show -d --resource-group $grupo --name $vm --query '{nome:name,estado:powerState,ip:publicIps}' --output table
if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel consultar a VM.' }

Write-Host 'Etapa Azure CLI encerrada. Continue pelo README para instalar Docker, enviar os arquivos e configurar o Oracle.'
