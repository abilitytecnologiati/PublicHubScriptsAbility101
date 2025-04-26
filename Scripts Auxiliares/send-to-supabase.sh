#!/bin/bash

# Parâmetros:
# $1 = API_URL
# $2 = API_KEY
# $3 = AUTHORIZATION
# $4 = BRANCH
# $5 = REPOSITORY
# $6 = COMMIT_ID
# $7 = COMMIT_MESSAGE
# $8 = PUSHER
# $9 = TIMESTAMP

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
curl --fail --show-error --silent --location "$API_URL" \
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
  }'
echo "Enviado com sucesso ✅"
