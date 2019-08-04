#!/bin/bash

source ./setenv.sh


docker stack up sdlc -c docker-compose.sdlc.yml
