#!/bin/bash
# load balancer 로그에서 waf rule, request url check scrip
# 사전에 필요한 로그 파일을 다운로드 받아야 한다.
# https://cloudlogging.app.goo.gl/QhuKRD6CVw8UdFJL6
# sample log 
#resource.type:(http_load_balancer) AND jsonPayload.enforcedSecurityPolicy.name:(was-external-clients-policy-dev)
#jsonPayload.previewSecurityPolicy.outcome="DENY"
#jsonPayload.enforcedSecurityPolicy.outcome="ACCEPT"

PROJECT="sample-gw-dev-000000"

file=$1

if [ -z $file ] ; then
    echo "usage) $0 filename"
    exit 1
fi

if ! [ -f $file ] ; then
    echo "$file is not exist."
    exit 1
fi

# waf 에서 체크한 rule 목록 뽑기
rules=`cat $file | jq -r '.[].jsonPayload.previewSecurityPolicy.preconfiguredExprIds[]'  | sort -u`

# .jsonPayload.previewSecurityPolicy.preconfiguredExprIds[0] : waf rule
# .httpRequest.requestUrl : requestUrl
# waf rule, requestUrl을 먼저 뽑은 후 찾으려고 하는 rule에 해당하는 requestUrl만 출력을 함

for rule in $rules
do
    echo "Id: $rule"
    cat $file | jq '.[] | {Id: .jsonPayload.previewSecurityPolicy.preconfiguredExprIds[0], requestUrl: .httpRequest.requestUrl}' \
    | jq -r --arg rule "$rule" '. | select(.Id==$rule)' | jq -r .requestUrl | uniq
    echo
done
