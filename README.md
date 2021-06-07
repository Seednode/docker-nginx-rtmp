# NGINX RTMP Relay

A minimal container for ingesting and playing back RTMP streams via the HLS or DASH protocols.

To build the image, run the following command:

`./build.sh [nginx_version]`

Optionally, you can specify the Docker registry to be used by prepending the `REGISTRY` environment variable:

`LATEST=yes ./build.sh`

DASH streams are stored in /var/www/html/dash, and HLS streams are stored in /var/www/html/hls.

Make sure to store these persistently if you want them to remain after stopping the container.

For example, to store the VODs in corresponding directories within your user home directory:

`docker run -it --rm -v $HOME/hls:/var/www/html/hls -v $HOME/dash:/var/www/html/dash local/nginx-rtmp:latest`
