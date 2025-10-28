FROM tomcat:9-jre17-temurin-focal AS base

ARG GEOSERVER_VERSION="2.28.0"
ENV GEOSERVER_VERSION=$GEOSERVER_VERSION
ENV GEOSERVER_URL="https://sourceforge.net/projects/geoserver/files/GeoServer/${GEOSERVER_VERSION}/geoserver-${GEOSERVER_VERSION}-war.zip"
ENV GEOSERVER_LIB_DIR="/usr/local/tomcat/webapps/geoserver/WEB-INF/lib"
ENV GDAL_PLUGIN_URL="https://sourceforge.net/projects/geoserver/files/GeoServer/${GEOSERVER_VERSION}/extensions/geoserver-${GEOSERVER_VERSION}-gdal-plugin.zip"
ENV CAS_PLUGIN_URL="https://sourceforge.net/projects/geoserver/files/GeoServer/${GEOSERVER_VERSION}/extensions/geoserver-${GEOSERVER_VERSION}-cas-plugin.zip"

RUN apt update && \
    apt -y --no-install-recommends install \
        gdal-bin \
        libgdal-dev \
        libgdal-java \
        libsqlite3-dev \
        sqlite3 \
        swig \
        unzip \
        wget && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

FROM base AS download-geoserver
RUN wget -qO /tmp/geoserver-war.zip "${GEOSERVER_URL}" && \
    unzip /tmp/geoserver-war.zip -d /tmp/geoserver-war && \
    unzip /tmp/geoserver-war/geoserver.war -d /usr/local/tomcat/webapps/geoserver && \
    rm -rf /tmp/geoserver*

FROM base AS download-gdal-plugin
RUN wget -qO /tmp/gdal-plugin.zip $GDAL_PLUGIN_URL && \
    unzip -o -d /tmp/gdal-plugin /tmp/gdal-plugin.zip && \
    rm -f /tmp/gdal-plugin.zip

FROM base AS download-cas-plugin
RUN wget -qO /tmp/cas-plugin.zip $CAS_PLUGIN_URL && \
    unzip -o -d /tmp/cas-plugin /tmp/cas-plugin.zip && \
    rm -f /tmp/cas-plugin.zip

FROM base AS final
COPY --from=download-geoserver /usr/local/tomcat/webapps/geoserver /usr/local/tomcat/webapps/geoserver
COPY --from=download-cas-plugin /tmp/cas-plugin/*.jar $GEOSERVER_LIB_DIR/
COPY --from=download-gdal-plugin /tmp/gdal-plugin/*.jar $GEOSERVER_LIB_DIR/

# Downgrade the gdal jar so it matches the gdal version installed on the system
RUN rm -f $GEOSERVER_LIB_DIR/gdal-3.2.0.jar && \
    cp /usr/share/java/gdal.jar $GEOSERVER_LIB_DIR/gdal-3.0.4.jar

# Ensure libgdalalljni.so is in the load path. If this isn't found, GeoServer will log and warn
# about that on startup.
ENV LD_LIBRARY_PATH="/usr/lib/jni:$LD_LIBRARY_PATH"
ENV GDAL_DATA="/usr/share/gdal"

# Redirect the root path to /geoserver/web
# Inspired by https://github.com/geoserver/docker/blob/master/startup.sh
RUN mkdir -p $CATALINA_HOME/webapps/ROOT
COPY files/index.jsp $CATALINA_HOME/webapps/ROOT/
COPY bin/run-tests /usr/local/bin/