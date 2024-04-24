#!/bin/bash

NAMESPACE="3scale"

EXCLUDE_WORDS=("deploy" "hook")

echo "Waiting for all pods in namespace $NAMESPACE not containing '${EXCLUDE_WORDS[@]}' in their name to be ready..."

while true; do
    # Get the list of pods in the namespace not containing the exclude words in their name
    NOT_RUNNING_PODS=$(oc get pods --namespace="$NAMESPACE" --no-headers | awk -v exclude="${EXCLUDE_WORDS[*]}" '{
        exclude_word_found = 0;
        for (i=1; i<=split(exclude, exclude_array); i++) {
            if ($1 ~ exclude_array[i]) {
                exclude_word_found = 1;
                break;
            }
        }
        if (exclude_word_found == 0 && $3 != "Running") {
            print $1;
        }
    }')

    # If there are no pods not in a running state, exit the loop
    if [ -z "$NOT_RUNNING_PODS" ]; then
        echo "All pods in namespace $NAMESPACE not containing '${EXCLUDE_WORDS[@]}' in their name are ready."
        break
    else
        echo "Waiting for the following pods not containing '${EXCLUDE_WORDS[@]}' in their name to be ready:"
        echo "$NOT_RUNNING_PODS"
    fi

    sleep 10  # Wait for 10 seconds before checking again
done