# GeoServer Docker Image

A Tomcat-based Docker image that installs and runs [GeoServer](https://geoserver.org/) with its CAS and GDAL plugins.

## Building the image

To build the default image:

```sh
docker compose build
```

You can also optionally set `GEOSERVER_VERSION` to the specific version of GeoServer you want built. The CAS and GDAL plugins are fetched relative to that version. Note that this is a Dockerfile build argument; it's just passed thru via the environment:

```sh
GEOSERVER_VERSION=2.27.3 docker compose build
```

## Running / testing

The following starts the app on `localhost:8080`. The test script just verifies that the default GeoServer login page is present.

```sh
docker compose up --wait
docker compose exec app run-tests
```
