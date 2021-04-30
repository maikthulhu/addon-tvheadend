#!/usr/bin/env bashio

bashio::log.info "[TVHeadend] Installing TVHeadend"
apk update && apk add --no-cache tvheadend=4.2.8-r3 git=2.31.1-r1 mono=6.12.0.122-r1

mkdir -p /config/tvheadend/recordings

bashio::log.info '[TVHeadend] Setup completed without errors!!'

mkdir -p ~/.wg++
ln -sf /config/tvheadend/wg++/guide.xml ~/.wg++/guide.xml

if  [ "$(ls -A /config/tvheadend/wg++)" ]; then
    bashio::log.info "[Webgrab+] Webgrab+ already installed"
else
    bashio::log.info "[Webgrab+] No webgrab+ installation found - Installing webgrab+"
    cd /tmp  && \
    wget http://www.webgrabplus.com/sites/default/files/download/SW/V2.1.0/WebGrabPlus_V2.1_install.tar.gz  && \
    tar -xvf WebGrabPlus_V2.1_install.tar.gz && rm WebGrabPlus_V2.1_install.tar.gz  && \
    mv .wg++/ /config/tvheadend/wg++  && \
    cd /config/tvheadend/wg++  && \
    ./install.sh

    rm -rf siteini.pack/  && \
    git clone https://github.com/DeBaschdi/webgrabplus-siteinipack.git  && \
    cp -R webgrabplus-siteinipack/siteini.pack/ siteini.pack  && \
    cp siteini.pack/International/horizon.tv.* siteini.user/
fi

wget -O /usr/bin/tv_grab_wg++ http://www.webgrabplus.com/sites/default/files/tv_grab_wg.txt  && \
chmod a+x /usr/bin/tv_grab_wg++

bashio::log.info '[Webgrab+] Setup completed without errors!!'

echo "0 0 * * * /config/tvheadend/wg++/run.sh" >> /var/spool/cron/root
crond

check_streamlink () {
  if [ -z "$(command -v streamlink)" ]; then return 1; else return 0; fi
}

streamlink_update () {
  if pip3 install --no-cache --upgrade streamlink; then
    bashio::log.info "[StreamLink] Streamlink version: $(streamlink --version)."
  else
    bashio::log.error '[StreamLink] Streamlink update failed!'
  fi
}

streamlink_install () {
  bashio::log.info '[StreamLink] APK: Updating pkg list.'
  if apk update; then
    bashio::log.info '[StreamLink] APK: Installing required packages.'
    if apk add --no-cache py3-pip && apk add --no-cache --virtual .build-deps gcc musl-dev; then
        bashio::log.info '[StreamLink] PIP3: Updating and installing required packages.'
        if ! pip3 install --no-cache --upgrade setuptools; then bashio::log.error '[StreamLink] PIP3: Error while upgrading setuptools.'; fi
        if ! pip3 install --no-cache streamlink; then bashio::log.error '[StreamLink] PIP3: Error while installing Streamlink.'; fi
    else
      bashio::log.info '[StreamLink] APK: Critical error. Unable install required packages.' 
      exit 1
    fi
    bashio::log.info '[StreamLink] APK: Removing packages no longer required.'
    apk del .build-deps gcc musl-dev
  else
    bashio::log.error '[StreamLink] APK: Critical error. Unable to update pkg list. Check connectivity.'
    exit 1
  fi
  bashio::log.info '[StreamLink] Finsihed all APK and PIP3 updates and installs.'
}

if check_streamlink; then
  bashio::log.info '[StreamLink] Updating Streamlink...' ; streamlink_update
else
  bashio::log.info '[StreamLink] Installing Streamlink...'; streamlink_install
fi

bashio::log.info '[StreamLink] Setup completed without errors!!' 