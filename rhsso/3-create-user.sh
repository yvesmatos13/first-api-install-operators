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

cd cli/bin

sh kcadm.sh config credentials --server https://$RHSSO_ROUTE/auth --realm master  --user $RHSSO_ADMIN_USER --password $RHSSO_ADMIN_PASSWORD

REALM_NAME=apicurio

USER_ID=$(sh kcadm.sh create users -r $REALM_NAME \
  -s username=studio \
  -s enabled=true \
  -s email=studio@apicurio.com \
  -s firstName=studio \
  -s lastName=apicurio \
  -s emailVerified=true \
  -s attributes.impersonate=impersonate \
  -i)

echo "User ID: $USER_ID"


sh kcadm.sh update users/$USER_ID/reset-password -r $REALM_NAME -s type=password -s value=redhat -s temporary=false -n


REALM_NAME=microcks

USER_ID=$(sh kcadm.sh create users -r $REALM_NAME \
  -s username=microcks \
  -s enabled=true \
  -s email=microcks@apicurio.com \
  -s firstName=microcks \
  -s lastName=apicurio \
  -s emailVerified=true \
  -s attributes.impersonate=impersonate \
  -i)

echo "User ID: $USER_ID"


sh kcadm.sh update users/$USER_ID/reset-password -r $REALM_NAME -s type=password -s value=redhat -s temporary=false -n

REALM_NAME=registry

USER_ID=$(sh kcadm.sh create users -r $REALM_NAME \
  -s username=registry \
  -s enabled=true \
  -s email=registry@apicurio.com \
  -s firstName=registry \
  -s lastName=apicurio \
  -s emailVerified=true \
  -s attributes.impersonate=impersonate \
  -i)

echo "User ID: $USER_ID"


sh kcadm.sh update users/$USER_ID/reset-password -r $REALM_NAME -s type=password -s value=redhat -s temporary=false -n
