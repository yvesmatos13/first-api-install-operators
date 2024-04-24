#/bin/bash

json='[
  {"id": "cc65bd6a-96ca-4887-9f11-b1e6967d71c3", "clientId": "3scale"},
  {"id": "dd7f2ad7-c749-46e4-95a4-d98f60a2697c", "clientId": "account"},
  {"id": "69b8d671-32f7-4f72-ad1a-61cf22d14b24", "clientId": "account-console"},
  {"id": "2485e0b6-369c-4d8d-83d1-4d9fc75cd2d5", "clientId": "admin-cli"},
  {"id": "7cdf0cda-903b-4b34-b041-89e06a5965c8", "clientId": "broker"},
  {"id": "8232e68f-ca0c-43cf-9d8c-7ccf92a272d0", "clientId": "realm-management"},
  {"id": "4fc1e31f-179d-4417-8b11-dbebfbce92f6", "clientId": "security-admin-console"}
]'

touch secrets.json

echo $json >> secrets.json

json_file="secrets.json"

json_content=$(<"$json_file")


client_id="3scale"

result=$(echo "$json_content" | jq -r --arg client_id "$client_id" '.[] | select(.clientId == $client_id) | .id')

if [ -n "$result" ]; then
  echo "ID for clientId=$client_id: $result"
else
  echo "No matching entry found for clientId=$client_id"
fi