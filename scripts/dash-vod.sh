#!/usr/bin/env ash
# generates an hls.js player for a recorded stream ingested by nginx-http-flv-module

# created files should not be world writeable
umask 002

# set root directory for serving streams
basedir="/var/www/html"

# set name of rtmp app
app="dash"

# set name of rtmp stream
stream="$1"

# set subdirectory which recorded streams will be served from
subdirectory="vods"

# set date for recording directory
date="$(date +%Y%m%d%H%M%S)"

# error out if no argument is provided
if [ "$#" -ne 1 ]; then
  exit 1;
fi

# create the stream directory
mkdir -p "$basedir"/"$subdirectory"/"$stream"/"$date"/

# move the existing files over to the new stream directory
mv "$basedir"/"$app"/"$stream"/* "$basedir"/"$subdirectory"/"$stream"/"$date"/

# create playback page
cat <<EOL > "$basedir"/"$subdirectory"/"$stream"/"$date"/index.html
<!doctype html>
<html>
    <body>
        <div>
            <video data-dashjs-player autoplay src="index.mpd" controls>
            </video>
        </div>
        <script src="js/dash.all.min.js"></script>
    </body>
</html>
EOL

# remove livestream directory now that the vod is online
rmdir "$basedir"/"$app"/"$stream"

