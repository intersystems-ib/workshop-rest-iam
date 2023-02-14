FROM containers.intersystems.com/intersystems/iris:2022.2.0.368.0
ARG WEBINAR_INCLUDE_API

USER root

# copy license
COPY iris.key /usr/irissys/mgr/iris.key

# create app directory
WORKDIR /opt/webinar
RUN chown -R irisowner:irisowner /opt/webinar

USER irisowner

# copy files (src, install, etc.)
COPY --chown=irisowner:irisowner iris.script iris.script
COPY --chown=irisowner:irisowner src src
COPY --chown=irisowner:irisowner install install

# include API implementation (or not)
WORKDIR /opt/webinar/
RUN echo "${WEBINAR_INCLUDE_API}"
RUN if [ "${WEBINAR_INCLUDE_API}" = "no" ]; then rm -rf src/Webinar/API/Leaderboard; fi

# download zpm
RUN mkdir -p /tmp/deps \
 && cd /tmp/deps \
 && wget -q https://pm.community.intersystems.com/packages/zpm/latest/installer -O zpm.xml

# run iris.script
RUN iris start IRIS \
    && iris session IRIS < /opt/webinar/iris.script \
    && iris stop IRIS quietly  