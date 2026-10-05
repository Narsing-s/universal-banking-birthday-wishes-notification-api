#!/usr/bin/env bash
set -euo pipefail

: "${ANYPOINT_CLIENT_ID:?ANYPOINT_CLIENT_ID is required}"
: "${ANYPOINT_CLIENT_SECRET:?ANYPOINT_CLIENT_SECRET is required}"
: "${ANYPOINT_ORG_ID:?ANYPOINT_ORG_ID is required}"
: "${CLOUDHUB_ENVIRONMENT:?CLOUDHUB_ENVIRONMENT is required}"
: "${CLOUDHUB_TARGET:?CLOUDHUB_TARGET is required}"
: "${CLOUDHUB_APPLICATION_NAME:?CLOUDHUB_APPLICATION_NAME is required}"

npm install -g anypoint-cli-v4-public >/dev/null 2>&1
export ANYPOINT_ORG="${ANYPOINT_ORG_ID}"
export ANYPOINT_ENV="${CLOUDHUB_ENVIRONMENT}"
anypoint-cli-v4 --version

token_response="$(
  curl -sS -X POST "https://anypoint.mulesoft.com/accounts/api/v2/oauth2/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "grant_type=client_credentials" \
    --data-urlencode "client_id=${ANYPOINT_CLIENT_ID}" \
    --data-urlencode "client_secret=${ANYPOINT_CLIENT_SECRET}"
)"
token="$(jq -r '.access_token // empty' <<<"${token_response}")"
test -n "${token}" || { echo "::error::Unable to obtain Anypoint access token."; exit 1; }

envs="$(
  curl -sS --fail-with-body \
    -H "Authorization: Bearer ${token}" \
    "https://anypoint.mulesoft.com/accounts/api/organizations/${ANYPOINT_ORG_ID}/environments"
)"
env_id="$(
  jq -r --arg name "${CLOUDHUB_ENVIRONMENT}" \
    '.. | objects | select(.name? == $name and .id?) | .id' <<<"${envs}" |
    head -n1
)"
test -n "${env_id}" || {
  echo "::error::Unable to resolve environment ID for ${CLOUDHUB_ENVIRONMENT}."
  exit 1
}

query="$(
  jq -nc --arg target "${CLOUDHUB_TARGET}" \
    '{provider:"MC",targetId:$target,offset:"0",limit:"100"}' |
    jq -sRr @uri
)"

deployments="$(
  curl -sS --fail-with-body \
    -H "Authorization: Bearer ${token}" \
    -H "X-ANYPNT-ORG-ID: ${ANYPOINT_ORG_ID}" \
    -H "X-ANYPNT-ENV-ID: ${env_id}" \
    "https://anypoint.mulesoft.com/amc/application-manager/api/v2/organizations/${ANYPOINT_ORG_ID}/environments/${env_id}/deployments?deploymentQuery=${query}"
)"

resolve_domain() {
  local app="$1"
  local app_id=""
  local described=""

  app_id="$(
    anypoint-cli-v4 runtime-mgr:application:list --output json |
      jq -r --arg app "${app}" '
        .. | objects
        | select(((.name? // .applicationName? // "") == $app) and (.id? != null))
        | .id
      ' |
      head -n1
  )"

  if [ -n "${app_id}" ] && [ "${app_id}" != "null" ]; then
    described="$(
      anypoint-cli-v4 runtime-mgr:application:describe "${app_id}" --output json 2>/dev/null || true
    )"

    jq -r '
      .. | strings
      | select(test("^https?://[^[:space:]]+\\.cloudhub\\.io/?$"))
      | sub("/$"; "")
    ' <<<"${described}" | head -n1
    return 0
  fi

  jq -r --arg app "${app}" '
    .. | objects
    | select((.name? // .applicationName? // "") == $app)
    | .. | strings
    | select(test("^https?://[^[:space:]]+\\.cloudhub\\.io/?$"))
    | sub("/$"; "")
  ' <<<"${deployments}" | head -n1
}

mkdir -p ui
domains=()

for region in west westb east; do
  app="${CLOUDHUB_APPLICATION_NAME}-${region}"
  domain="$(resolve_domain "${app}")"

  if [ -z "${domain}" ]; then
    echo "::error::Could not resolve live CloudHub URL for ${app}."
    exit 1
  fi

  domain="${domain%/}"
  echo "${region^^}: ${domain}"
  domains+=("${domain}/api")
done

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
jq -n \
  --arg generatedAt "${generated_at}" \
  --arg west "${domains[0]}" \
  --arg westb "${domains[1]}" \
  --arg east "${domains[2]}" \
  '{version:2,generatedAt:$generatedAt,apiBases:[$west,$westb,$east]}' \
  > ui/api-config.json

cat ui/api-config.json
