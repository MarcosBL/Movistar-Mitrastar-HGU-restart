#!/usr/bin/env bash
set -eou pipefail

# Configuración del usuario
router_ip='192.168.1.100'
router_password='XXXXXXXXX'

# Variables
router_user='1234'
host="http://$router_ip"
auth="$router_user:$router_password"
session_file="/tmp/mitracookies.txt"
readonly CURL_PATH="$(command -v curl || echo '/usr/bin/curl')"

echo "Iniciando sesión y obteniendo cookies..."
sessionKey=$(echo -n "$auth" | base64)
"$CURL_PATH" -s --http0.9 -c "$session_file" -X POST "$host/login-login.cgi" --data "sessionKey=$sessionKey&pass=" > /dev/null 2>&1

echo "Obteniendo formulario de reinicio..."
result=$($CURL_PATH -s --http0.9 -b "$session_file" -X GET "$host/resetrouter.html")

echo "Realizando reinicio final..."
match=$(echo "$result" | grep -o "var sessionKey='[0-9]\+'")
sessionKey=$(echo "$match" | grep -o "[0-9]\+")
params="sessionKey=$sessionKey"
result=$($CURL_PATH -s --http0.9 -b "$session_file" -X GET "$host/rebootinfo.cgi?$params")

# Imprimir el resultado
if [[ $result == *"The Broadband Router is rebooting"* ]]; then
    echo "✅ ¡Reiniciando!"
else
    echo "💥 Ops... ¡algo falló!"
fi
