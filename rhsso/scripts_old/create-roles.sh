#!/bin/sh

# Login no Openshift
USER=admin
GUIDE="qxhp4"
SANDBOXID=2918
PASSWORDD=gDf2uaDmtUFkg30B
NAMESPACE=rhsso
DEPLOYMENT_CONFIG_NAME=sso
API_SERVER=https://api.cluster-$GUIDE.$GUIDE.sandbox$SANDBOXID.opentlc.com:6443

oc login -u $USER -p $PASSWORDD $API_SERVER --insecure-skip-tls-verify=true

RHSSO_ROUTE=$(oc get route sso  -n $NAMESPACE --template='{{.spec.host}}')
RHSSO_ADMIN_USER=admin
RHSSO_ADMIN_PASSWORD=rhsso


#INICIO DA ETAPA 7 DO DOCUMENTO

#Get RHSSO admin password

cd rh-sso-7.6/bin

REALM_NAME="3scale-api"

sh kcadm.sh config credentials --server https://$RHSSO_ROUTE/auth --realm master  --user $RHSSO_ADMIN_USER --password $RHSSO_ADMIN_PASSWORD

CLIENTS=$(sh kcadm.sh get clients -r $REALM_NAME --fields id,clientId,secret)

CLIENTS_VARIABLE=$(echo $CLIENTS | jq -r '.')

CLIENT_ID="3scale"

ID=$(echo "$CLIENTS_VARIABLE" | jq -r --arg client_id "$CLIENT_ID" '.[] | select(.clientId == $client_id) | .id')

if [ -n "$ID" ]; then
  echo "ID for clientId=$CLIENT_ID: $ID"
else
  echo "No matching entry found for clientId=$CLIENT_ID"
fi


CLIENT_ID="realm-management"
ROLE_NAME="manage-clients"
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="rhsso"


sh kcadm.sh create clients/$CLIENT_ID/service-account-user -r $REALM_NAME \
  --service-account-roles realm-management/manage-clients

# Get the role ID
#ROLE_ID=$(sh kcadm.sh get roles -realm $REALM_NAME  --fields id,name --format json | jq -r '.[] | select(.name == "$ROLE_NAME") | .id')
#echo $ROLE_ID

# Add the role to the "realm-management" client
#sh kcadm.sh add-roles --realm $REALM_NAME --users clientId:$CLIENT_ID --rol‌​es "$ROLE_NAME"