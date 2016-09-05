FROM fedora:24
LABEL date="Sat Jul  9 15:51:34 CEST 2016"

MAINTAINER <sofer@sathlan.org>

ENV container=docker

RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do \
    [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*; \
    rm -f /etc/systemd/system/*.wants/*; \
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*; \
    rm -f /lib/systemd/system/anaconda.target.wants/*;

RUN sed -i -e 's/^#ForwardToConsole=.*/ForwardToConsole=yes/' \
    -e 's,^#TTYPath=/dev/console,TTYPath=/dev/console,' \
    -e 's/^#*MaxLevelConsole=.*/MaxLevelConsole=debug /' \
    /etc/systemd/journald.conf

RUN dnf upgrade -y && dnf clean all && systemd-machine-id-setup

VOLUME ["/run", "/tmp"]

CMD ["/usr/sbin/init"]
