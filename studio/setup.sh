#!/bin/bash

oc new-project studio

oc project studio

oc process -f apicurio-image-streams-template.yml | oc apply -f -
oc process -f apicurio-postgresql-deployment-config-template.yml | oc apply -f -
oc process -f apicurio-deployment-configs-template.yml | oc apply -f -
oc process -f apicurio-services-template.yml | oc apply -f -
oc process -f apicurio-routes-template.yml | oc apply -f -

#Fetch Openshift route values

uirurl=$(oc get route apicurio-studio-ui -o go-template --template='{{.spec.host}}{{println}}')
apiurl=$(oc get route apicurio-studio-api -o go-template --template='{{.spec.host}}{{println}}')
wsurl=$(oc get route apicurio-studio-ws -o go-template --template='{{.spec.host}}{{println}}')
authurl=$(oc get route sso -n rhsso --template='{{.spec.host}}')


#Set Openshift route values based on fetch


oc set env dc/apicurio-studio-ui APICURIO_KC_AUTH_URL=https://"$authurl/auth"
oc set env dc/apicurio-studio-ui APICURIO_UI_HUB_API_URL=https://"$apiurl"
oc set env dc/apicurio-studio-ui APICURIO_UI_EDITING_URL=wss://"$wsurl"
oc set env dc/apicurio-studio-ui APICURIO_UI_FEATURE_MICROCKS=true


oc set env dc/apicurio-studio-api APICURIO_KC_AUTH_URL=https://"$authurl/auth"
oc set env dc/apicurio-studio-api APICURIO_MICROCKS_API_URL=https://microcks.apps.cluster-qxhp4.qxhp4.sandbox2918.opentlc.com/api
oc set env dc/apicurio-studio-api APICURIO_MICROCKS_CLIENT_ID=microcks-serviceaccount
oc set env dc/apicurio-studio-api APICURIO_MICROCKS_CLIENT_SECRET=ab54d329-e435-41ae-a900-ec6b3fe15c54

echo Apicurio Studio available at: "$uirurl"
