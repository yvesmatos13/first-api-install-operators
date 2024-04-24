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

#sh kcadm.sh get realms

#create helms - 3scale-api 3scale-admin 3scale-devportal

sh kcadm.sh create realms  -f ../../realms/apicurio-realm-novo.json

sh kcadm.sh create realms  -f ../../realms/registry-realm-novo.json

sh kcadm.sh create realms  -f ../../realms/microcks-realm-novo.json

sh kcadm.sh create clients -r microcks --file ../../realms/microcks-serviceaccount.json
