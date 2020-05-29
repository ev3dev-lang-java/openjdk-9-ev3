FROM ev3dev-lang-java:jdk-package

USER root
COPY . /opt/jdktest/
RUN chmod +x /opt/jdktest/runner.sh

WORKDIR /opt/jdktest
CMD ["/bin/bash", "-c", "/opt/jdktest/autorun.sh"]
