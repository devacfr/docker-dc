
# Development Environment using Docker

Based on work of https://github.com/sameersbn and following documentation:
- https://blog.jakehamilton.dev/the-belly-of-the-whale/
- https://medium.com/@demily.clement/auto-g%C3%A9n%C3%A9rer-un-certificat-et-configurer-traefik-pour-utiliser-le-ssl-en-local-9b66206e8fb6
- https://www.objectif-libre.com/fr/blog/2018/05/23/valorisez-metriques-prometheus-cloudkitty-traefic/
- https://github.com/vegasbrianc/docker-traefik-prometheus
- https://github.com/stefanprodan/swarmprom
- https://gist.github.com/javierprovecho/0f5a766ebe30527caa9f429fa7652586
- https://aperogeek.fr/prometheus-monitor-docker-services-with-grafana/
- https://github.com/vegasbrianc/prometheus
- https://www.24joursdeweb.fr/2018/mon-infrastructure-en-tant-que-hebergeur-web-independant/

## Docker Infractruscture

### Forwarding dnsmasq DNS to Consul

https://learn.hashicorp.com/consul/security-networking/forwarding

### Monitoring

#### grafana

- https://github.com/vegasbrianc/docker-traefik-prometheus, use the dashboad and datasource provisionning.

## Docker Sdlc

## Gitlab

NOTE: Please allow a couple of minutes for the GitLab application to start.

Point your browser to http://gitlab.docker and login using the default username and password:

  username: root
  password: 5iveL!fe

### SSL

Access to the gitlab application can be secured using SSL so as to prevent unauthorized access to the data in your repositories. While a CA certified SSL certificate allows for verification of trust via the CA, a self signed certificate can also provide an equal level of trust verification as long as each client takes some additional steps to verify the identity of your website. I will provide instructions on achieving this towards the end of this section.

Jump to the [Using HTTPS with a load balancer](#using-https-with-a-load-balancer) section if you are using a load balancer such as hipache, haproxy or nginx.

To secure your application via SSL you basically need two things:
- **Private key (.key)**
- **SSL certificate (.crt)**

When using CA certified certificates, these files are provided to you by the CA. When using self-signed certificates you need to generate these files yourself. Skip to [Strengthening the server security](#strengthening-the-server-security) section if you are armed with CA certified SSL certificates.

#### Generation of a Self Signed Certificate

Generation of a self-signed SSL certificate involves a simple 3-step procedure:

**STEP 1**: Create the server private key

```bash
openssl genrsa -out gitlab.key 2048
```

**STEP 2**: Create the certificate signing request (CSR)

```bash
openssl req -new -key gitlab.key -out gitlab.csr
```

**STEP 3**: Sign the certificate using the private key and CSR

```bash
openssl x509 -req -days 3650 -in gitlab.csr -signkey gitlab.key -out gitlab.crt
```

Congratulations! You now have a self-signed SSL certificate valid for 10 years.

#### Strengthening the server security

This section provides you with instructions to [strengthen your server security](https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html). To achieve this we need to generate stronger DHE parameters.

```bash
openssl dhparam -out dhparam.pem 2048
```

#### Installation of the SSL Certificates

Out of the four files generated above, we need to install the `gitlab.key`, `gitlab.crt` and `dhparam.pem` files at the gitlab server. The CSR file is not needed, but do make sure you safely backup the file (in case you ever need it again).

The default path that the gitlab application is configured to look for the SSL certificates is at `/home/git/data/certs`, this can however be changed using the `SSL_KEY_PATH`, `SSL_CERTIFICATE_PATH` and `SSL_DHPARAM_PATH` configuration options.

If you remember from above, the `/home/git/data` path is the path of the [data store](#data-store), which means that we have to create a folder named `certs/` inside `/srv/docker/gitlab/gitlab/` and copy the files into it and as a measure of security we'll update the permission on the `gitlab.key` file to only be readable by the owner.

```bash
mkdir -p /srv/docker/gitlab/gitlab/certs
cp gitlab.key /srv/docker/gitlab/gitlab/certs/
cp gitlab.crt /srv/docker/gitlab/gitlab/certs/
cp dhparam.pem /srv/docker/gitlab/gitlab/certs/
chmod 400 /srv/docker/gitlab/gitlab/certs/gitlab.key
```

Great! we are now just one step away from having our application secured.

#### Enabling HTTPS support

HTTPS support can be enabled by setting the `GITLAB_HTTPS` option to `true`. Additionally, when using self-signed SSL certificates you need to the set `SSL_SELF_SIGNED` option to `true` as well. Assuming we are using self-signed certificates

```bash
docker run --name gitlab -d \
    --publish 10022:22 --publish 10080:80 --publish 10443:443 \
    --env 'GITLAB_SSH_PORT=10022' --env 'GITLAB_PORT=10443' \
    --env 'GITLAB_HTTPS=true' --env 'SSL_SELF_SIGNED=true' \
    --volume /srv/docker/gitlab/gitlab:/home/git/data \
    sameersbn/gitlab:12.0.3
```

In this configuration, any requests made over the plain http protocol will automatically be redirected to use the https protocol. However, this is not optimal when using a load balancer.

#### Configuring HSTS

HSTS if supported by the browsers makes sure that your users will only reach your sever via HTTPS. When the user comes for the first time it sees a header from the server which states for how long from now this site should only be reachable via HTTPS - that's the HSTS max-age value.

With `NGINX_HSTS_MAXAGE` you can configure that value. The default value is `31536000` seconds. If you want to disable a already sent HSTS MAXAGE value, set it to `0`.

```bash
docker run --name gitlab -d \
 --env 'GITLAB_HTTPS=true' --env 'SSL_SELF_SIGNED=true' \
 --env 'NGINX_HSTS_MAXAGE=2592000' \
 --volume /srv/docker/gitlab/gitlab:/home/git/data \
 sameersbn/gitlab:12.0.3
```

If you want to completely disable HSTS set `NGINX_HSTS_ENABLED` to `false`.

#### Using HTTPS with a load balancer

Load balancers like nginx/haproxy/hipache talk to backend applications over plain http and as such the installation of ssl keys and certificates are not required and should **NOT** be installed in the container. The SSL configuration has to instead be done at the load balancer.

However, when using a load balancer you **MUST** set `GITLAB_HTTPS` to `true`. Additionally you will need to set the `SSL_SELF_SIGNED` option to `true` if self signed SSL certificates are in use.

With this in place, you should configure the load balancer to support handling of https requests. But that is out of the scope of this document. Please refer to [Using SSL/HTTPS with HAProxy](http://seanmcgary.com/posts/using-sslhttps-with-haproxy) for information on the subject.

When using a load balancer, you probably want to make sure the load balancer performs the automatic http to https redirection. Information on this can also be found in the link above.

In summation, when using a load balancer, the docker command would look for the most part something like this:

```bash
docker run --name gitlab -d \
    --publish 10022:22 --publish 10080:80 \
    --env 'GITLAB_SSH_PORT=10022' --env 'GITLAB_PORT=443' \
    --env 'GITLAB_HTTPS=true' --env 'SSL_SELF_SIGNED=true' \
    --volume /srv/docker/gitlab/gitlab:/home/git/data \
    sameersbn/gitlab:12.0.3
```

Again, drop the `--env 'SSL_SELF_SIGNED=true'` option if you are using CA certified SSL certificates.

In case GitLab responds to any kind of POST request (login, OAUTH, changing settings etc.) with a 422 HTTP Error, consider adding this to your reverse proxy configuration:

`proxy_set_header X-Forwarded-Ssl on;` (nginx format)

#### Establishing trust with your server

This section deals will self-signed ssl certificates. If you are using CA certified certificates, your done.

This section is more of a client side configuration so as to add a level of confidence at the client to be 100 percent sure they are communicating with whom they think they.

This is simply done by adding the servers certificate into their list of trusted certificates. On ubuntu, this is done by copying the `gitlab.crt` file to `/usr/local/share/ca-certificates/` and executing `update-ca-certificates`.

Again, this is a client side configuration which means that everyone who is going to communicate with the server should perform this configuration on their machine. In short, distribute the `gitlab.crt` file among your developers and ask them to add it to their list of trusted ssl certificates. Failure to do so will result in errors that look like this:

```bash
git clone https://git.local.host/gitlab-ce.git
fatal: unable to access 'https://git.local.host/gitlab-ce.git': server certificate verification failed. CAfile: /etc/ssl/certs/ca-certificates.crt CRLfile: none
```

You can do the same at the web browser. Instructions for installing the root certificate for firefox can be found [here](http://portal.threatpulse.com/docs/sol/Content/03Solutions/ManagePolicy/SSL/ssl_firefox_cert_ta.htm). You will find similar options chrome, just make sure you install the certificate under the authorities tab of the certificate manager dialog.

There you have it, that's all there is to it.

#### Installing Trusted SSL Server Certificates

If your GitLab CI server is using self-signed SSL certificates then you should make sure the GitLab CI server certificate is trusted on the GitLab server for them to be able to talk to each other.

The default path image is configured to look for the trusted SSL certificates is at `/home/git/data/certs/ca.crt`, this can however be changed using the `SSL_CA_CERTIFICATES_PATH` configuration option.

Copy the `ca.crt` file into the certs directory on the [datastore](#data-store). The `ca.crt` file should contain the root certificates of all the servers you want to trust. With respect to GitLab CI, this will be the contents of the gitlab_ci.crt file as described in the [README](https://github.com/sameersbn/docker-gitlab-ci/blob/master/README.md#ssl) of the [docker-gitlab-ci](https://github.com/sameersbn/docker-gitlab-ci) container.

By default, our own server certificate [gitlab.crt](#generation-of-self-signed-certificate) is added to the trusted certificates list.