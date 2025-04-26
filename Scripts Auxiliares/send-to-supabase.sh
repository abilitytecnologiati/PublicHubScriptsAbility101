#!/bin/bash

API_URL="$1"
API_KEY="$2"
AUTHORIZATION="$3"
BRANCH="$4"
REPOSITORY="$5"
COMMIT_ID="$6"
COMMIT_MESSAGE="$7"
PUSHER="$8"
TIMESTAMP="$9"

echo "Enviando informações para Supabase..."
response=$(curl --fail --show-error --silent --location "$API_URL" \
  --header "apikey: $API_KEY" \
  --header "Authorization: $AUTHORIZATION" \
  --header "Content-Type: application/json" \
  --data '{
    "branch": "'"$BRANCH"'",
    "repository": "'"$REPOSITORY"'",
    "commit_id": "'"$COMMIT_ID"'",
    "commit_message": "'"$COMMIT_MESSAGE"'",
    "pusher": "'"$PUSHER"'",
    "timestamp": "'"$TIMESTAMP"'",
    "processado": false
  }' 2>&1)

status=$?

if [ $status -eq 0 ]; then
  echo "Enviado com sucesso ✅"
else
  echo "❌ Falha ao enviar para Supabase!"
  echo "URL tentada: $API_URL"
  echo "Primeiros 10 caracteres da API_KEY: ${API_KEY:0:10}"
  echo "Detalhes do erro:"
  echo "$response"
  exit 1
fi
