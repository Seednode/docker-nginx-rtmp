# NGINX RTMP Relay

A minimal container for ingesting and playing back RTMP streams via the HLS or DASH protocols.

DASH streams are stored in /var/www/html/dash, and HLS streams are stored in /var/www/html/hls.
Make sure to store these persistently if you want them to remain after stopping the container.

For example,
`docker run -it --rm -v $HOME/hls:/var/www/html/hls -v $HOME/dash:/var/www/html/dash local/nginx-rtmp:1.19.4`, to store the VODs in corresponding directories within your user home directory.
