FROM containers.intersystems.com/intersystems/iris:2020.2.0.211.0

USER root

COPY --chown=$ISC_PACKAGE_MGRUSER:$ISC_PACKAGE_IRISGROUP irissession.sh /
RUN chmod +x /irissession.sh

# copy source code
RUN mkdir -p /opt/webinar/install
COPY install /opt/webinar/install
RUN mkdir -p /opt/webinar/src
COPY src /opt/webinar/src/

# change permissions to IRIS user
RUN chown -R ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/webinar

USER irisowner

# download zpm package manager
RUN mkdir -p /tmp/deps \
 && cd /tmp/deps \
 && wget -q https://pm.community.intersystems.com/packages/zpm/latest/installer -O zpm.xml


SHELL ["/irissession.sh"]

RUN \
    zn "USER" \
    # load & compile source code
    do $system.OBJ.Load("/opt/webinar/src/Webinar/Installer.cls", "ck") \
    do ##class(Webinar.Installer).Run() \
    # install zpm & webterminal
    zn "WEBINAR" \
    Do $system.OBJ.Load("/tmp/deps/zpm.xml", "ck") \
    zpm "install webterminal" \
    set sc = 1 

# bringing the standard shell back
SHELL ["/bin/bash", "-c"]   