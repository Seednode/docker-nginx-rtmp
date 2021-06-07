# NGINX RTMP Relay

A minimal container for ingesting and playing back RTMP streams via the HLS or DASH protocols.

To build the image, run the following command:

`./build.sh [nginx_version]`

Optionally, you can specify the Docker registry to be used by prepending the `REGISTRY` environment variable:

`LATEST=yes ./build.sh`

DASH streams are stored in /var/www/html/dash, and HLS streams are stored in /var/www/html/hls.

Make sure to store these persistently if you want them to remain after stopping the container.

For example, to store the VODs in corresponding directories within your user home directory:

`docker run -it --rm -v -v ${HOME}/dash:/var/www/html/dash -v ${HOME}/hls:/var/www/html/hls local/nginx-rtmp:latest`

To stream via OBS, under the Stream section:

Set "Service" to "Custom..."

Set "Server" to "rtmp://your.ip.address.here/dash" for DASH or "rtmp://your.ip.address.here/hls" for HLS

Set "Stream Key" to the directory you'd like to stream to, for example "seednode" would result in the following paths:

DASH stream: http://your.ip.address.here/dash/seednode/

HLS stream: http://your.ip.address.here/hls/seednode/

VODs: http://your.ip.address.here/vods/seednode/
