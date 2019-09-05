#!/bin/bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

openssl req -x509 -new -keyout "${dir}/certs/root.key" -out "${dir}/certs/root.cer" -config "${dir}/conf/root.cnf"
openssl req -nodes -new -keyout "${dir}/certs/server.key" -out "${dir}/certs/server.csr" -config "${dir}/conf/server.cnf"
openssl x509 -days 825 -req -in "${dir}/certs/server.csr" -CA "${dir}/certs/root.cer" -CAkey "${dir}/certs/root.key" -set_serial 123 -out "${dir}/certs/server.cer" -extfile "${dir}/conf/server.cnf" -extensions x509_ext