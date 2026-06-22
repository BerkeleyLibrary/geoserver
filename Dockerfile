ARG GEOSERVER_VERSION="2.28.4"

FROM docker.osgeo.org/geoserver:${GEOSERVER_VERSION}-gdal

COPY bin/run-tests /usr/local/bin/