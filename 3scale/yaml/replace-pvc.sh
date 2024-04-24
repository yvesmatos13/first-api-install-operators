#!/bin/bash

pvc_file=pvc.yaml

# Define the new ownerReferences:uid value

new_owner_references_uid=$(oc get apimanager 3scale-apimanager -o=jsonpath='{.metadata.uid}')

echo $new_owner_references_uid

#Update the ownerReferences:uid value in the PVC YAML file
sed  "s/uid: .*/uid: $new_owner_references_uid/" "$pvc_file" > new_pvc.yaml

oc delete pvc system-storage -n 3scale

oc apply -f new_pvc.yaml -n 3scale