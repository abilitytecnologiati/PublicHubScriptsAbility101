param (
    [string]$Username,
    [string]$Password,
    [string]$Repo,
    [string]$Organization,
    [int]$PageSize = 1,
    [string]$Ordering = "last_updated",
    [int]$Sleep = 40
)

Write-Host "📦 Verificando dependência do 'jq'..."
if (-not (Get-Command "jq.exe" -ErrorAction SilentlyContinue)) {
    Write-Host "⚠️ 'jq' não encontrado. Baixe e coloque 'jq.exe' no PATH ou mesmo diretório do script." -ForegroundColor Yellow
    Exit 1
} else {
    Write-Host "✅ jq está disponível."
}

Write-Host "⏳ Aguardando $Sleep segundos para sincronização no Docker Hub..."
Start-Sleep -Seconds $Sleep

# ========= LOGIN =========
Write-Host "🔐 Realizando login no Docker Hub com usuário $Username..."
$loginBody = @{
    username = $Username
    password = $Password
} | ConvertTo-Json

$tokenResponse = Invoke-RestMethod -Method Post `
    -Uri "https://hub.docker.com/v2/users/login" `
    -Headers @{ "Content-Type" = "application/json" } `
    -Body $loginBody

$Token = $tokenResponse.token

if ([string]::IsNullOrWhiteSpace($Token)) {
    Write-Host "❌ Erro ao obter token. Verifique suas credenciais." -ForegroundColor Red
    Exit 1
}
Write-Host "✅ Token JWT obtido com sucesso."

# ========= CONSULTA ÚLTIMA TAG =========
Write-Host "📦 Consultando a última tag publicada do repositório $Repo..."
$tagInfo = Invoke-RestMethod -Uri "https://hub.docker.com/v2/repositories/${Repo}/tags/?page_size=$PageSize&ordering=$Ordering" `
    -Headers @{ Authorization = "Bearer $Token" }

$tagName = $tagInfo.results[0].name
$tagDigest = $tagInfo.results[0].digest
$tagDate = $tagInfo.results[0].last_updated

Write-Host "🧷 Última tag: $tagName"
Write-Host "🔐 Digest: $tagDigest"
Write-Host "📅 Atualizado: $tagDate"

# ========= DOCKER SCOUT =========
Write-Host "`n📊 Buscando Docker Scout Health Score..."
$scoutBody = @{
    context = @{ organization = $Organization }
    images = @(@{
        name = $Repo
        tag = $tagName
        digest = $tagDigest
    })
} | ConvertTo-Json -Depth 3

$scoutResponse = Invoke-RestMethod -Uri "https://api.scout.docker.com/v1/policy/insights/org-image-score/images" `
    -Method Post `
    -Headers @{
        Authorization = "Bearer $Token"
        Accept = "application/json"
        "Content-Type" = "application/json"
    } `
    -Body $scoutBody

$score = $scoutResponse.results[0].result.score

if ([string]::IsNullOrWhiteSpace($score)) {
    Write-Host "❌ Nenhum score encontrado. Verifique se há política ativa no Docker Scout." -ForegroundColor Red
} else {
    Write-Host "🏅 Score de Segurança: $score"
}

# ========= SUMMARY (GitHub Actions) =========
if ($score -and $score -ne "null") {
    $color = "gray"
    switch ($score) {
        "A" { $color = "green" }
        "B" { $color = "limegreen" }
        "C" { $color = "orange" }
        "D" { $color = "darkorange" }
        "E" { $color = "orangered" }
        "F" { $color = "red" }
    }

    $summary = @()
    $summary += "## 🔍 Resultado do Docker Scout"
    $summary += ""
    $summary += "**📦 Repositório:** `$Repo`"
    $summary += "**🏷️ Última tag:** `$tagName`"
    $summary += "**🔐 Digest:** `$tagDigest`"
    $summary += "**📅 Atualizado:** `$tagDate`"
    $summary += ""
    $summary += "**🏅 Score de Segurança:** <span style=`"color:$color;font-weight:bold;font-size:1.2em`">$score</span>"
    $summary += ""
    $summary += "### 🛡 Políticas Avaliadas"
    
    foreach ($policy in $scoutResponse.results[0].result.policies) {
        $label = $policy.label
        $status = $policy.status.ToUpper()
        $summary += "- $label: $status"
    }

    $summaryPath = $env:GITHUB_STEP_SUMMARY
    if ($summaryPath) {
        $summary -join "`n" | Out-File -FilePath $summaryPath -Encoding utf8
    }

    if ($score -ne "A" -and $score -ne "B") {
        Write-Host ""
        Write-Host "❌ Deploy ABORTADO por motivo de segurança!" -ForegroundColor Red
        Write-Host "🔒 Score: $score (inadequado para produção)"
        Write-Host "ℹ️ Verifique o resumo no GitHub Actions para mais detalhes."
        Exit 2
    }
}
