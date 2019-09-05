#!/bin/bash

export HOST_DOMAIN="docker"
export HOST_IP="$(ip -4 addr show eth0 | grep -Po 'inet \K[\d.]+')"

ip_arr=($(echo $HOST_IP))
export HOST_IP="${ip_arr[0]}"
export HOST_IP="127.0.0.1"

export TRAEFIK_HOST="traefik.${HOST_DOMAIN}"
export PORTAINER_HOST="portainer.${HOST_DOMAIN}"
export PROMETHEUS_HOST="prometheus.${HOST_DOMAIN}"
export GRAFANA_HOST="grafana.${HOST_DOMAIN}"

export GITLAB_HOST="gitlab.${HOST_DOMAIN}"
export REGISTRY_HOST="registry.${HOST_DOMAIN}"

######################################################################
# TRAEFIK
######################################################################
TRAEFIK_PUBLIC_TAG="traefik-public"

######################################################################
# CONSUL
######################################################################
export CONSUL_REPLICAS=1

######################################################################
# GITLAB
######################################################################


# Database settings, change at least the password
export GITLAB_DB_USER="gitlab"
export GITLAB_DB_PASS="password"
export GITLAB_DB_NAME="gitlabhq_production"

# URL to GitLab, change this to your domain
export GITLAB_HOST="gitlab.${HOST_DOMAIN}"

# GitLab secrets, change these
export GITLAB_SECRETS_DB_KEY_BASE="long-and-random-alphanumeric-string"
export GITLAB_SECRETS_SECRET_KEY_BASE="long-and-random-alphanumeric-string"
export GITLAB_SECRETS_OTP_KEY_BASE="long-and-random-alphanumeric-string"

# GitLab email configuration, change these to your email
export GITLAB_EMAIL="devacfr@mac.com"
export GITLAB_EMAIL_REPLY_TO="devacfr@mac.com"
export GITLAB_INCOMING_EMAIL_ADDRESS="devacfr@mac.com"

# GitLab email authentication
# Here's an example of using Gmail authentication
export GITLAB_SMTP_ENABLED="false"

######################################################################
# REGISTRY
######################################################################

# Registry realm
# Make sure to replace this with your domain
export REGISTRY_AUTH_TOKEN_REALM="https://${GITLAB_HOST}/jwt/auth"

######################################################################
# GRAFNA
######################################################################

export GF_SERVER_ROOT_URL="https://grafana.${HOST_DOMAIN}"
export GF_SECURITY_ADMIN_PASSWORD="admin"
export GF_USERS_ALLOW_SIGN_UP="false"
export GF_INSTALL_PLUGINS="grafana-piechart-panel,grafana-clock-panel"
