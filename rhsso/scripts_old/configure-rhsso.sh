#!/bin/sh

# Login no Openshift
API_SERVER=https://api.cluster-fgkpf.fgkpf.sandbox2550.opentlc.com:6443
USER=admin
PASSWORDD=aQ8MLjsDe9zdJOV6
NAMESPACE=rhsso

oc login -u $USER -p $PASSWORDD $API_SERVER --insecure-skip-tls-verify=true

RHSSO_ROUTE=$(oc get route sso  -n $NAMESPACE --template='{{.spec.host}}')
RHSSO_ADMIN_USER=admin
RHSSO_ADMIN_PASSWORD=rhsso


#INICIO DA ETAPA 7 DO DOCUMENTO

#Get RHSSO admin password

cd rh-sso-7.6/bin

sh kcadm.sh config credentials --server https://$RHSSO_ROUTE/auth --realm master  --user $RHSSO_ADMIN_USER --password $RHSSO_ADMIN_PASSWORD

#sh kcadm.sh get realms

#create helms - 3scale-api 3scale-admin 3scale-devportal

sh kcadm.sh create realms -s realm=3scale-api -s enabled=true

sh kcadm.sh create realms -s realm=3scale-admin -s enabled=true

sh kcadm.sh create realms -s realm=3scale-devportal -s enabled=true

#create client for 3scale-api realm

REALM_NAME="3scale-api"
CLIENT_ID="3scale"
NAME="3scale AMP"
DESCRIPTION="3scale AMP"
CONSENT_REQUIRED="false"
CLIENT_PROTOCOL="openid-connect"
ACCESS_TYPE="confidential"
STANDARD_FLOW_ENABLED="false"
IMPLICIT_FLOW_ENABLED="false"
DIRECT_ACCESS_GRANTS_ENABLED="true"
AUTHORIZATION_ENABLED="false"
PUBLIC_CLIENT="false"

sh kcadm.sh create clients -r $REALM_NAME \
    -s clientId="$CLIENT_ID" \
    -s name="$NAME" \
    -s description="$DESCRIPTION" \
    -s consentRequired="$CONSENT_REQUIRED" \
    -s protocol="$CLIENT_PROTOCOL" \
    -s directAccessGrantsEnabled="$DIRECT_ACCESS_GRANTS_ENABLED" \
    -s standardFlowEnabled="$STANDARD_FLOW_ENABLED" \
    -s implicitFlowEnabled="$IMPLICIT_FLOW_ENABLED" \
    -s serviceAccountsEnabled=true \
    -s authorizationServicesEnabled="$AUTHORIZATION_ENABLED" \
    -s publicClient=$PUBLIC_CLIENT

#SERVICE ACCOUNT ROLE
sh kcadm.sh create clients/$CLIENT_ID/service-account-user -r $REALM_NAME --service-account-roles realm-management/manage-clients


#GET CLIENT SECRET



touch ../../json/secrets.json


sh kcadm.sh get clients -r $REALM_NAME --fields id,clientId,secret >> ../../json/secrets.json


json_file="../../json/secrets.json"

json_content=$(<"$json_file")

echo $json_content

client_id="3scale"

result=$(echo "$json_content" | jq -r --arg client_id "$client_id" '.[] | select(.clientId == $client_id) | .id')

#CLIENT SECRET ID
echo $result

if [ -n "$result" ]; then
  echo "ID for clientId=$client_id: $result
else
  echo "No matching entry found for clientId=$client_id"
fi

rm -rf ../../json/secrets.json


# CRIAÇÃO DE USUÁRIO 
USER_ID=$(sh kcadm.sh create users -r $REALM_NAME \
  -s username=johndoe \
  -s enabled=true \
  -s email=johndoe@foobar.co \
  -s firstName=john \
  -s lastName=doe \
  -s emailVerified=true \
  -s attributes.impersonate=impersonate \
  -i)

echo "User ID: $USER_ID"

# ATRIBUIÇÃO DE PASSWORD PARA O USUÁRIO
sh kcadm.sh set-password -r $REALM_NAME --username johndoe --new-password passwdtemp 
sh kcadm.sh update users/$USER_ID/reset-password -r $REALM_NAME -s type=password -s value=redhat -s temporary=false -n


