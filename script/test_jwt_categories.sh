#!/bin/bash

# Configurazione
SITE_URL="http://localhost:8080"
USERNAME="testuser"
PASSWORD="testpassword"

# Connessione JWT
echo "🔐 Connessione al server..."
JWT_RESPONSE=$(curl -s -X POST "${SITE_URL}/?rest_route=/simple-jwt-login/v1/auth" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}")

TOKEN=$(echo $JWT_RESPONSE | grep -o '"jwt":"[^"]*' | sed 's/"jwt":"//')

if [ -z "$TOKEN" ]; then
  echo "❌ Errore: impossibile ottenere il token JWT"
  echo "Response: $JWT_RESPONSE"
  exit 1
fi

echo "✅ Token ottenuto: ${TOKEN:0:20}..."

# Test 1: GET Categorie
echo ""
echo "📁 Test 1: GET Categorie (search=test)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "${SITE_URL}/wp-json/wc/v3/products/categories?search=test&per_page=100" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

echo "HTTP Status: $HTTP_CODE"
if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ GET Categorie funziona!"
  echo "Response: $BODY" | head -c 200
else
  echo "❌ GET Categorie fallito"
  echo "Response: $BODY"
fi

# Test 2: POST Categoria
echo ""
echo "📁 Test 2: POST Categoria (creazione)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${SITE_URL}/wp-json/wc/v3/products/categories" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Categoria Script",
    "slug": "test-categoria-script"
  }')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

echo "HTTP Status: $HTTP_CODE"
if [ "$HTTP_CODE" = "201" ]; then
  echo "✅ POST Categoria funziona!"
  CATEGORY_ID=$(echo "$BODY" | grep -o '"id":[0-9]*' | head -1 | sed 's/"id"://')
  echo "Categoria creata con ID: $CATEGORY_ID"
elif [ "$HTTP_CODE" = "400" ] && echo "$BODY" | grep -q "already exists"; then
  echo "ℹ️ Categoria già esistente (normale)"
else
  echo "❌ POST Categoria fallito"
  echo "Response: $BODY"
fi

# Test 3: GET Tag
echo ""
echo "🏷️ Test 3: GET Tag (search=test)"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "${SITE_URL}/wp-json/wc/v3/products/tags?search=test&per_page=100" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

echo "HTTP Status: $HTTP_CODE"
if [ "$HTTP_CODE" = "200" ]; then
  echo "✅ GET Tag funziona!"
else
  echo "❌ GET Tag fallito"
  echo "Response: $BODY"
fi

echo ""
echo "🎯 Test completati!"
