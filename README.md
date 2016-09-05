# docker-fedora-24-systemd.

[![Docker Automated buil](https://img.shields.io/docker/automated/sathlan/f24-systemd.svg?maxAge=86400)]()
[![GitHub release](https://img.shields.io/github/release/sathlan/docker-f24-systemd.svg?maxAge=86400)]()

A fedora 24 docker image that runs with systemd enabled.

The advantages are:
 - no more custom script for running service, just enable them
 - log is handled on the journald host
 - ripping zombie is properly handled
 - signal are properly handled

## Install

```
$ docker run -v /sys/fs/cgroup:/sys/fs/cgroup:ro -t \
    -d --name f24 sathlan/f24-systemd
$ docker exec -ti exec f24 bash

# inside the container
$ dnf install -y nginx
$ systemctl enable nginx
$ systemctl start nginx
```

## Building from Dockerfile

Create a simple dockerfile, where you enable the service and redirect
the log.

```Dockerfile
FROM sathlan/f24-systemd
RUN dnf install -y nginx && dnf clean all
RUN sed -ie 's,.*access_log.*,access_log ^Cslog:server=unix:/dev/log;,' /etc/nginx/nginx.conf
RUN systemctl enable nginx
```

Build in and run it.

```
docker build -t my/nginx .
docker run -p 80:80 -v /sys/fs/cgroup:/sys/fs/cgroup:ro -t \
   -d --name nginx my/nginx
```

From the host you have the access log in the journal.

```
journalctl -f CONTAINER_NAME=nginx -a &
curl -s 127.0.0.1:80 >/dev/null
```

## Test

The host should be CentOS or Fedora. The user running the test should
have `systemd-journal` permission to be able to read the host journal.

```
$ bundle install
$ bundle exec rake spec:f24-systemd
$ bundle exec rake spec:localhost
```

The test are dependants. You need to run `spec:f24-systemd` before
running `spec:localhost` as the former create the service inside the
image whose log will be checked in the journal.

## Other implementation

 - [vlisivka/docker-centos7-systemd-unpriv](https://github.com/vlisivka/docker-centos7-systemd-unpriv)
