ARG DEBIAN_RELEASE=stretch
ARG BUILD_TYPE=cross
FROM ev3dev-lang-java:jdk-$BUILD_TYPE-$DEBIAN_RELEASE
ARG DEBIAN_RELEASE
ARG BUILD_TYPE

ENV BUILDER_DISTRO=$DEBIAN_RELEASE
ENV BUILDER_TYPE=$BUILD_TYPE

ARG commit=unknown
ENV BUILDER_COMMIT=${commit}

ARG extra=none
ENV BUILDER_EXTRA=${extra}

# copy build patches & scripts
COPY *.awk *.patch *.sh /opt/jdkcross/
RUN chmod +x /opt/jdkcross/*.sh

# this directory should be mounted
VOLUME /build

USER compiler
WORKDIR /opt/jdkcross
CMD ["/opt/jdkcross/autorun.sh"]
