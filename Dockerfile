FROM bitnami/minideb:latest as builder

MAINTAINER LJR <lollspam@free.fr>

# Set the working directory to /app
WORKDIR /builddir

# Copy the current directory contents into the container at /app
ADD . /builddir

# Make port 80 available to the world outside this container
EXPOSE 8080

# Install build dependencies
RUN install_packages openssl ca-certificates
RUN install_packages libldap-dev libssl-dev
RUN install_packages git sed 
RUN install_packages g++ make

# get elog sources from bitbucket
RUN git clone https://bitbucket.org/ritt/elog --recursive

# build ELOG with LDAP and Intel(R) Celeron(R) CPU J3455 compatibily
# patch elog test size and list max
RUN cd /builddir/elog && \
    sed -i '/^#ifdef HAVE_LDAP.*/a #define LDAP_DEPRECATED 1' src/auth.cxx && \
    sed -i 's/^#define MAX_N_LIST.*/#define MAX_N_LIST 500/' src/elogd.h && \
    sed -i 's/^#define TEXT_SIZE.*/#define TEXT_SIZE 500000/' src/elogd.h && \
    sed -i 's/         if (get_user_line(lbs, user/         if (get_user_line(lbs, (char *) user/' src/auth.cxx && \
    sed -i 's|/bin/sh|/bin/bash|g' src/elogd.cxx && \
    make USE_LDAP=1 CXXFLAGS+='-Wno-sign-compare -march=core2 -mno-avx -mno-avx2 -mno-fma -msse4.1 -msse4.2 -mno-bmi -mno-bmi2' && \
    make install && \
    git log -n 1 --pretty=format:'%ad.%h' --date=short > /etc/elogd.version && \
    rm -r /builddir/elog/

FROM bitnami/minideb:latest

# Install build files
COPY --from=builder /usr/local/elog/ /usr/local/elog/
COPY --from=builder /usr/local/sbin/elogd /usr/local/sbin/elogd
COPY --from=builder /usr/local/bin/elog /usr/local/bin/elog
COPY --from=builder /usr/local/bin/elconv /usr/local/bin/elconv

# Install build dependencies
RUN install_packages imagemagick bash
RUN install_packages openssl ca-certificates
RUN install_packages libldap-2.5-0

# Adding default config files from build folder
COPY ./elogd.cfg /usr/local/elog/elogd.cfg

# This block only modifies permissions for non-mounted versions
RUN addgroup -gid 1031 elog && \
    adduser -uid 1031 -gid 1031 elog && \
    cd /usr/local/elog/ && \
    chown elog:elog elogd.cfg && \
    chown -R elog:elog logbooks

# Debug
#CMD ["/usr/local/sbin/elogd", "-v", "3", "-p", "8080", "-c", "/usr/local/elog/elogd.cfg"]
CMD ["/usr/local/sbin/elogd", "-p", "8080", "-c", "/usr/local/elog/elogd.cfg"]
