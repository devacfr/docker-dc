#!/bin/bash

source ./setenv.sh

docker stack up infra -c docker-compose.infra.yml
