param(
    [string]$API_URL,
    [string]$API_KEY,
    [string]$AUTHORIZATION,
    [string]$BRANCH,
    [string]$REPOSITORY,
    [string]$COMMIT_ID,
    [string]$COMMIT_MESSAGE,
    [string]$PUSHER,
    [string]$TIMESTAMP
)

# Monta o JSON
$payload = @{
    branch         = $BRANCH
    repository     = $REPOSITORY
    commit_id      = $COMMIT_ID
    commit_message = $COMMIT_MESSAGE
    pusher         = $PUSHER
    timestamp      = $TIMESTAMP
    processado     = $false
} | ConvertTo-Json -Depth 3

Write-Host "Enviando informações para Supabase..."

try {
    $response = Invoke-RestMethod -Uri $API_URL `
                                  -Method Post `
                                  -Headers @{
                                      "apikey"       = $API_KEY
                                      "Authorization"= $AUTHORIZATION
                                      "Content-Type" = "application/json"
                                  } `
                                  -Body $payload

    Write-Host "Enviado com sucesso ✅"
}
catch {
    Write-Host "❌ Falha ao enviar para Supabase!"
    Write-Host "========================================"
    Write-Host "URL tentada: $API_URL"
    Write-Host "Primeiros 10 caracteres da API_KEY: $($API_KEY.Substring(0,10))"
    Write-Host "JSON enviado:"
    Write-Host $payload
    Write-Host "Erro retornado:"
    Write-Host $_.Exception.Message
    Write-Host "========================================"
    exit 1
}
