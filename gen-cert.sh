#!/bin/bash
openssl req -x509 -new -keyout ./certs/root.key -out ./certs/root.cer -config ./conf/root.cnf
openssl req -nodes -new -keyout ./certs/server.key -out ./certs/server.csr -config server.cnf
openssl x509 -days 825 -req -in ./certs/server.csr -CA ./certs/root.cer -CAkey ./certs/root.key -set_serial 123 -out ./certs/server.cer -extfile ./conf/server.cnf -extensions x509_ext