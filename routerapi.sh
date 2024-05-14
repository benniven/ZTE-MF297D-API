#!/bin/bash

#########################
py_parse_waiv="import sys, json; print(json.load(sys.stdin)['wa_inner_version'])"
py_parse_crv="import sys, json; print(json.load(sys.stdin)['cr_version'])"
py_parse_LD="import sys, json; print(json.load(sys.stdin)['LD'])"
py_parse_RD="import sys, json; print(json.load(sys.stdin)['RD'])"
IP="192.168.1.1"
REF="Referer: http://$IP/"
URL_GET_CMD="http://$IP/goform/goform_get_cmd_process"
URL_SET_CMD="http://$IP/goform/goform_set_cmd_process"

#########################
echo "Reading LD"
LD=$(curl -s -H "$REF" -d "?isTest=false&cmd=LD&_=$(date +%s%3N)" $URL_GET_CMD | python -c "$py_parse_LD")
echo "LD=$LD"

#########################
echo -e "\nReading Language Info"
LANGINFO=$(curl -s -H "$REF" -d "isTest=false&cmd=Language%2Ccr_version%2Cwa_inner_version&multi_data=1&_=$(date +%s%3N)" $URL_GET_CMD)
echo $LANGINFO
cr_version=$( printf "$LANGINFO" | python -c "$py_parse_crv" )
wa_inner_version=$( printf "$LANGINFO" | python -c "$py_parse_waiv" )
a=$(printf "$wa_inner_version$cr_version" | sha256sum | cut -d" " -f 1 | awk '{print toupper($1)}')
echo "a=$a"

function generateAD {
  u=$(curl -s -H "$REF" -d "isTest=false&cmd=RD&_=$(date +%s%3N)" $URL_GET_CMD | python -c "$py_parse_RD" )
  printf "$a$u" | sha256sum | cut -d" " -f 1 | awk '{print toupper($1)}'
}

#########################
echo -e "\nLOGIN"
echo -n Please enter your router password: 
read -s PWD
PWDHASH=$(printf $PWD | sha256sum | cut -d" " -f 1 | awk '{print toupper($1)}')
URLPWD=$(printf $PWDHASH$LD | sha256sum | awk '{print toupper($1)}')
curl -s -c session.txt -H "$REF" -d "isTest=false&goformId=LOGIN&password=$URLPWD" $URL_SET_CMD
ZSIDN=$(cat session.txt | grep zsidn | cut -d\" -f2)
COOKIE="Cookie: zsidn=\"$ZSIDN\""
echo -e "\n$COOKIE"

##########################
#echo -e "\nSwitching WIFI ON"
#AD=$(generateAD)
#echo "AD=$AD"
#curl -s -H "$REF" -H "$COOKIE" -d "goformId=switchWiFiModule&isTest=false&SwitchOption=1&wifi_lbd_enable=1&AD=$AD" $URL_SET_CMD

##########################
echo -e "\nSwitching WIFI OFF"
AD=$(generateAD)
echo "AD=$AD"
curl -s -H "$REF" -H "$COOKIE" -d "goformId=switchWiFiModule&isTest=false&SwitchOption=0&wifi_lbd_enable=1&AD=$AD" $URL_SET_CMD

##########################
echo -e "\n\nQuery WIFI status"
curl -s -H "$REF" -H "$COOKIE" -d "isTest=false&cmd=queryWiFiModuleSwitch&_=$(date +%s%3N)" $URL_GET_CMD

##########################
echo -e "\n\nLOGOUT"
AD=$(generateAD)
echo "AD=$AD"
curl -s -H "$REF" -H "$COOKIE" -d  "isTest=false&goformId=LOGOUT&AD=$AD" $URL_SET_CMD
