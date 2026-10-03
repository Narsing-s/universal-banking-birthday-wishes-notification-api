#!/usr/bin/env bash
set -euo pipefail
: "${OID:?OID is required}"
: "${CID:?CID is required}"
: "${CSEC:?CSEC is required}"
ASSET_ID="universal-banking-birthday-wishes-notification-api"
VERSION="1.0.3"
JAR="target/${ASSET_ID}-${VERSION}-mule-application.jar"
test -s "$JAR" || { echo "::error::Expected Exchange JAR not found: $JAR"; exit 1; }
test -s "pom.xml" || { echo "::error::pom.xml not found"; exit 1; }
token_response=$(curl -sS -w '\n%{http_code}' -X POST 'https://anypoint.mulesoft.com/accounts/api/v2/oauth2/token' -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'grant_type=client_credentials' --data-urlencode "client_id=$CID" --data-urlencode "client_secret=$CSEC")
status=$(printf '%s\n' "$token_response" | tail -n1)
body=$(printf '%s\n' "$token_response" | sed '$d')
if [ "$status" != "200" ]; then echo "::error::Exchange authentication failed with HTTP $status."; exit 1; fi
token=$(printf '%s' "$body" | jq -r '.access_token // empty')
if [ -z "$token" ]; then echo "::error::No Exchange bearer token returned."; exit 1; fi
response=$(curl -sS -w '\n%{http_code}' -X POST "https://anypoint.mulesoft.com/exchange/api/v2/organizations/$OID/assets/$OID/$ASSET_ID/$VERSION" -H 'Accept: application/json, text/plain, */*' -H "Authorization: Bearer $token" -H 'x-sync-publication: true' -F "files.pom=@pom.xml" -F "files.mule-application.jar=@$JAR")
pub_status=$(printf '%s\n' "$response" | tail -n1)
pub_body=$(printf '%s\n' "$response" | sed '$d')
case "$pub_status" in
  200|201) echo "Exchange publication succeeded." ;;
  409) echo "Exchange asset version already exists; continuing." ;;
  *) echo "::error::Exchange publication failed with HTTP $pub_status."; echo "$pub_body" | head -c 2000; exit 1 ;;
esac