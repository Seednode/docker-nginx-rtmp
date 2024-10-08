#!/usr/bin/env ash
# generates an hls.js player for a live stream ingested by nginx-http-flv-module

# created files should not be world writeable
umask 002

# set root directory for serving streams
basedir="/var/www/html"

# set name of nginx app (name of application block in nginx.conf)
app="hls"

# set name of rtmp stream (input passed from `exec_publish` statement in nginx.conf)
stream="$1"

# error out if no argument is provided
if [ "$#" -ne 1 ]; then
  exit 1;
fi

# create the base directory
mkdir -p "$basedir"/"$app"/"$stream"

# create playback page
cat <<EOL > "$basedir"/"$app"/"$stream"/index.html
<script src="/js/hls.js"></script>
<video id="video" controls></video>
<script>
  var video = document.getElementById('video');
  if(Hls.isSupported()) {
    var hls = new Hls();
    hls.loadSource('index.m3u8');
    hls.attachMedia(video);
    hls.on(Hls.Events.MANIFEST_PARSED,function() {
      video.play();
    });
  }
  else if (video.canPlayType('application/vnd.apple.mpegurl')) {
    video.src = 'index.m3u8';
    video.addEventListener('loadedmetadata',function() {
      video.play();
    });
  }
</script>
EOL
