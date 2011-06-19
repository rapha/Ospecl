#!/bin/sh
set -o errexit

server="./$1_server"
client="./$1_client"

trap "echo 'Killing servers' >&2; jobs -l | awk '/examples/ {print \$2}' | xargs kill" EXIT

$server -I "$(pwd)/examples/" -l 7000 &
$server -I "$(pwd)/examples/" -l 7001 &
$server -I "$(pwd)/examples/" -l 7002 &
$server -I "$(pwd)/examples/" -l 7003 &
$server -I "$(pwd)/examples/" -l 7004 &

echo '=== 0 servers 0 specs ==='
$client
echo '=== 1 server 1 spec ==='
$client -color -address 127.0.0.1:7000 $(pwd)/examples/account_spec.ml
echo '=== 2 servers 1 spec ==='
$client -color -address 127.0.0.1:7000 -address 127.0.0.1:7000 $(pwd)/examples/account_spec.ml 
echo '=== 1 server 2 specs ==='
$client -color -address 127.0.0.1:7000 $(pwd)/examples/account_spec.ml $(pwd)/examples/account_spec.ml
echo '=== 2 servers 2 specs ==='
$client -color -address 127.0.0.1:7000 -address 127.0.0.1:7000 $(pwd)/examples/account_spec.ml $(pwd)/examples/account_spec.ml
echo '=== 24 servers 24 specs (different addresses) ==='
jot -b "$(pwd)/examples/account_spec.ml" 24 | xargs $client -color -address 127.0.0.1:7000 -address 127.0.0.1:7001 -address 127.0.0.1:7002 -address 127.0.0.1:7003 -address 127.0.0.1:7004
