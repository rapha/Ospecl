#!/bin/sh
set -o errexit

trap "jobs -l | awk '/ospecl_server/ {print \$2}' | xargs kill" EXIT

# check for syntax errors before starting servers
#jocaml jospecl_client

./ospecl_server -I examples/ -l 7000 &
./ospecl_server -I examples/ -l 7001 &
./ospecl_server -I examples/ -l 7002 &
./ospecl_server -I examples/ -l 7003 &
./ospecl_server -I examples/ -l 7004 &

echo '=== 0 servers 0 specs ==='
./jospecl_client
echo '=== 1 server 1 spec ==='
./jospecl_client -color -address 127.0.0.1:7000 -j 1 `pwd`/examples/account_spec.ml
echo '=== 2 servers 1 spec ==='
./jospecl_client -color -address 127.0.0.1:7000 -j 2 `pwd`/examples/account_spec.ml
echo '=== 1 server 2 specs ==='
./jospecl_client -color -address 127.0.0.1:7000 -j 1 `pwd`/examples/account_spec.ml `pwd`/examples/account_spec.ml
echo '=== 2 servers 2 specs ==='
./jospecl_client -color -address 127.0.0.1:7000 -j 2 `pwd`/examples/account_spec.ml `pwd`/examples/account_spec.ml
echo '=== 24 servers 24 specs (different addresses) ==='
jot -b "$(pwd)/examples/account_spec.ml" 24 | xargs ./jospecl_client -color -j 1 -address 127.0.0.1:7000 -address 127.0.0.1:7001 -address 127.0.0.1:7002 -address 127.0.0.1:7004
