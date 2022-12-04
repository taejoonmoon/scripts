#!/bin/bash

#instance_list=`gcloud compute instances list | grep -v NAME | awk '{ print $1 }'`
instance_list=`gcloud compute instances list | egrep -v 'NAME|TERMINATED' | awk '{ print $1 }'`

for list in $instance_list
do
    echo $list
    gcloud compute instances describe "$list" --format="json" |  jq .metadata.items | jq  '.[0].value'
    echo
done

