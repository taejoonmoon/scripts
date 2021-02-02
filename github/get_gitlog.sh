#!/usr/bin/env bash
# get github commit list with github api 
# set GITHUB_TOKEN to your GitHub or GHE access token 
# 
# https://docs.github.com/en/rest/guides/getting-started-with-the-rest-api
# https://docs.github.com/en/rest/reference/repos#get-a-commit
# json to csv
# https://e.printstacktrace.blog/how-to-convert-json-to-csv-from-the-command-line/

# export GITHUB_TOKEN=xxxxxxxxxxxxxxxx

token=$GITHUB_TOKEN

if [ -n "$token" ]; then
  token_cmd="Authorization: token $token"
else
  echo "You must set a Personal Access Token to the GITHUB_TOKEN environment variable"
  exit 1
fi

git_repo="HANGLAS/hanglas-iac"
since="2020-12-14" 
#now=`date "+%Y-%m-%d %H:%M:%S"`
now=`date "+%Y-%m-%d"`
#until="2020-12-19"

if ! [ -n "$until" ]; then
  until=$now
fi

temp_json=temp.json

curl -s -H "$token_cmd" \
"https://api.github.com/repos/$git_repo/commits?since=$since&until=$until" \
| jq '[.[] | {message: .commit.message, name: .commit.committer.name, date: .commit.author.date}]' \
> $temp_json 

jq -r 'map({name,date,message}) | (first | keys_unsorted) as $keys | map([to_entries[] | .value]) as $rows | $keys,$rows[] | @csv' $temp_json \
| sed -e 's/\"//g'  > temp.csv
#| sed -e 's/\"//g'  -e 's/T[0-9:]*Z//g'

cat temp.csv

test -f $temp_json && rm -fv $temp_json
