#!/bin/bash

# ========== PARAMETERS ==========
USERNAME=""
PASSWORD=""
REPO=""
ORGANIZATION=""
PAGE_SIZE=1
ORDERING="last_updated"

# ========== CHECK DEPENDENCIES ==========
echo "📦 Verificando dependências..."
if ! command -v jq &> /dev/null; then
  echo "⚙️ Instalando jq..."
  sudo apt-get update -y
  sudo apt-get install -y jq
else
  echo "✅ jq já está instalado."
fi


# ========== PARSE ARGUMENTS ==========
while [[ $# -gt 0 ]]; do
  case "$1" in
    --username) USERNAME="$2"; shift 2 ;;
    --password) PASSWORD="$2"; shift 2 ;;
    --repo) REPO="$2"; shift 2 ;;
    --organization) ORGANIZATION="$2"; shift 2 ;;
    --page-size) PAGE_SIZE="$2"; shift 2 ;;
    --ordering) ORDERING="$2"; shift 2 ;;
    *)
      echo "❌ Opção inválida: $1"
      echo "Use: --username USER --password TOKEN --repo REPO --organization ORG [--page-size N] [--ordering CRITERIA]"
      exit 1
      ;;
  esac
done

# ========== LOGIN ==========
echo "🔐 Realizando login no Docker Hub com usuário $USERNAME..."
TOKEN_RESPONSE=$(curl -s --location "https://hub.docker.com/v2/users/login" \
  --header "Content-Type: application/json" \
  --data "{
    \"username\": \"$USERNAME\",
    \"password\": \"$PASSWORD\"
  }")

TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r .token)

if [[ "$TOKEN" == "null" || -z "$TOKEN" ]]; then
  echo "❌ Erro ao obter token. Verifique suas credenciais."
  exit 1
fi

echo "✅ Token JWT obtido com sucesso."

# ========== CONSULTA ÚLTIMA TAG ==========
echo "📦 Consultando a última tag publicada do repositório $REPO..."

TAG_INFO=$(curl -s --location "https://hub.docker.com/v2/repositories/${REPO}/tags/?page_size=${PAGE_SIZE}&ordering=${ORDERING}" \
  --header "Authorization: Bearer $TOKEN")

TAG_NAME=$(echo "$TAG_INFO" | jq -r '.results[0].name')
TAG_DIGEST=$(echo "$TAG_INFO" | jq -r '.results[0].digest')
TAG_DATE=$(echo "$TAG_INFO" | jq -r '.results[0].last_updated')

echo "🧷 Última tag: $TAG_NAME"
echo "🔐 Digest: $TAG_DIGEST"
echo "📅 Atualizado: $TAG_DATE"

# ========== CONSULTA SCORE DOCKER SCOUT ==========
echo ""
echo "📊 Buscando Docker Scout Health Score..."

SCOUT_SCORE_RESPONSE=$(curl -s --location "https://api.scout.docker.com/v1/policy/insights/org-image-score/images" \
  --header "accept: application/json" \
  --header "authorization: Bearer $TOKEN" \
  --header "content-type: application/json" \
  --data "{
    \"context\": {\"organization\": \"$ORGANIZATION\"},
    \"images\": [{
      \"name\": \"$REPO\",
      \"tag\": \"$TAG_NAME\",
      \"digest\": \"$TAG_DIGEST\"
    }]
  }")

SCORE=$(echo "$SCOUT_SCORE_RESPONSE" | jq -r '.results[0].result.score')

if [[ "$SCORE" == "null" || -z "$SCORE" ]]; then
  echo "❌ Nenhum score encontrado. Verifique se há política ativa no Docker Scout."
else
  echo "🏅 Score de Segurança: $SCORE"
fi

# ========== DETALHE DAS POLÍTICAS ==========
echo ""
echo "🛡 Políticas Avaliadas:"
echo "------------------------"

echo "$SCOUT_SCORE_RESPONSE" | jq -r '.results[0].result.policies[] | "- \(.label): \(.status | ascii_upcase)"'

# ========== DEBUG RAW OUTPUT ==========
echo ""
echo "🐞 JSON bruto retornado pelo Docker Scout:"
echo "-----------------------------------------"
echo "$SCOUT_SCORE_RESPONSE" | jq .