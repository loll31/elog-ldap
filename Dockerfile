FROM alpine:3.13

MAINTAINER LJR <lollspam@free.fr>

# Set the working directory to /app
WORKDIR /builddir

# Copy the current directory contents into the container at /app
ADD . /builddir

# Make port 80 available to the world outside this container
EXPOSE 8080

# Install build dependencies
RUN apk update -q && \
    apk add --no-cache openssl-dev libldap openldap-dev sed imagemagick && \
    apk add --no-cache --virtual .build-deps build-base git

# get elog sources from bitbucket
RUN git clone https://bitbucket.org/ritt/elog --recursive

# build ELOG with LDAP
RUN cd /builddir/elog && \
    sed -i '/^#ifdef HAVE_LDAP.*/a #define LDAP_DEPRECATED 1' src/auth.cxx && \
    sed -i 's/         if (get_user_line(lbs, user/         if (get_user_line(lbs, (char *) user/' src/auth.cxx && \
    make USE_LDAP=1 && \
    make install && \
    apk del .build-deps && \
    rm -r /builddir/elog/

# Adding users and config files from build folder
COPY ./elogd.cfg /usr/local/elog/elogd.cfg

# This block only modifies permissions for non-mounted versions
RUN adduser -S -g elog elog && \
    addgroup -S elog && \
    cd /usr/local/elog/ && \
    chown elog:elog elogd.cfg && \
    chown -R elog:elog logbooks

CMD ["/usr/local/sbin/elogd", "-p", "8080", "-c", "/home/elogd.cfg"]
