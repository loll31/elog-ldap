# elog-ldap
ELOG logbook manager with ldap authentification in an Alpine based docker.

This Dockerfile creates a docker image of an elog server (https://midas.psi.ch/elog/) built on Alpine linux (https://alpinelinux.org/).
This version is a fork of **fincle/elog-alpine** docker with LDAP support.

The idea is to build the lightest possible deployment so that it may be run on a lab computer with many other common tools: i.e. to have the least possible overhead.

A number of other docker builds use Ubuntu and Debian, and, therefore contain a lot of unnecessary stuff. This is an attempt to make it as small as possible with all config and data stored in an mounted volume external to the container.

## Building the docker image locally
Pull docker from github with
```
git clone --recursive https://github.com/loll31/elog-ldap
cd ./elog-ldap
```

You can modify the elogd.cfg file if you like, or not, and then build
```
docker build -t elog-ldap .
```

You can also get the images directly from docker, useful if you want to deploy directly

```
docker pull usinagaz/elog-ldap
```

To run the docker image on local machine
```
docker run -p 8080:8080 \
  --mount source=my-logbooks,target=/usr/local/elog/logbooks \
  --mount source=/path/to/elogd.cfg,target=/usr/local/elog/elogd.cfg \
  --mount source=/path/to/elogd.passwd,target=/etc/elogd.passwd \
  elog-ldap:latest
```

Here my-logbooks is a docker defined volume, this can be made with 
```
docker volume create my-logbooks
```
or by any other way you make/mount a volue to docker.

You can then access from a browser at http://localhost:8080

## Some asides
The current image builds from alpine:3.13 (make fails with 3.14) and the lastest released version of elog. 
In time I will pin down versions so that the docker is stable against changes in the dependancies.

This ELOG Docker provides ImageMagick and CKeditor (included in ELOG scripts sources).
