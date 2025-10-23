#!/bin/bash

# Configurazione
SITE_URL="http://127.0.0.1:8080"
USERNAME="testuser"
PASSWORD="testpassword"

# Connessione JWT
echo "Connessione al server..."
JWT_RESPONSE=$(curl -s -X POST "${SITE_URL}/?rest_route=/simple-jwt-login/v1/auth" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}")

TOKEN=$(echo $JWT_RESPONSE | grep -o '"jwt":"[^"]*' | sed 's/"jwt":"//')

if [ -z "$TOKEN" ]; then
  echo "Errore: impossibile ottenere il token JWT"
  exit 1
fi

echo "Token ottenuto"

# Creazione prodotto
echo "Creazione prodotto..."
curl -s -X POST "${SITE_URL}/wp-json/wc/v3/products" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Prodotto Test Script",
    "type": "simple",
    "regular_price": "19.99",
    "description": "Prodotto creato tramite script bash",
    "short_description": "Test prodotto",
    "status": "publish"
  }'
