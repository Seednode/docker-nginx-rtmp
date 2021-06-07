# NGINX RTMP Relay

## Building the image

A minimal container for ingesting and playing back RTMP streams via the HLS or DASH protocols.

To build the image, clone the repository and run the following command, optionally specifying an nginx version to build:

`./build.sh [nginx_version]`

Optionally, you can specify the Docker registry to be used by prepending the `REGISTRY` environment variable:

`REGISTRY=docker.seedno.de/seednode ./build.sh`

If no registry is specified, the images will be built as `local/nginx-rtmp:<version>`.

If a registry is specified, the built images will be pushed to it once the build is finished.

If you would like images to also be tagged as `latest`, you can specify `LATEST=yes` as an environment variable:

`LATEST=yes ./build.sh`

These environment variables and arguments can be combined:

`REGISTRY=docker.seedno.de/seednode LATEST=yes ./build.sh 1.21.0`

The resulting images from the above command might look like this:

```
sinc@crimson ~ docker images
REPOSITORY                                      TAG            IMAGE ID       CREATED        SIZE
docker.seedno.de/seednode/nginx-rtmp            1.21.0         6e60200a2454   7 hours ago    18.2MB
docker.seedno.de/seednode/nginx-rtmp            latest         6e60200a2454   7 hours ago    18.2MB
```

## Running the container

DASH streams are stored inside the container in `/var/www/html/dash`, and HLS streams are stored in `/var/www/html/hls`.

Make sure to store these persistently if you want them to remain after stopping the container.

For example, to store the VODs in corresponding directories within your user home directory:

`docker run --detach --rm --mount type=bind,source=${HOME}/dash,destination=/var/www/html/dash --mount type=bind,source=${HOME}/hls,destination=/var/www/html/hls local/nginx-rtmp:latest`

Make sure these directories exist prior to running the above command.

## Streaming with OBS

To stream via OBS, under the Stream section:

Set `Service` to `Custom...`

Set `Server` to `rtmp://your.ip.address.here/dash` for DASH or `rtmp://your.ip.address.here/hls` for HLS

Set `Stream Key` to the directory you'd like to stream to, for example a stream key of `seednode` would result in the following paths:

DASH stream: `http://your.ip.address.here/dash/seednode/`

HLS stream: `http://your.ip.address.here/hls/seednode/`

VODs: `http://your.ip.address.here/vods/seednode/`
