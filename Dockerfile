#FROM python:3.6-slim

FROM ubuntu

RUN echo "deb http://archive.ubuntu.com/ubuntu trusty multiverse" >> /etc/apt/sources.list
RUN echo "deb http://archive.ubuntu.com/ubuntu trusty-updates multiverse" >> /etc/apt/sources.list

# 先更新apt-get
RUN apt-get update && apt-get upgrade -y

# 安装python3
RUN apt-get install python3 -y

# 安装FFmpeg
RUN apt-get install ffmpeg -y

# 安装bottle
RUN apt-get install python3-pip -y
RUN pip3 install bottle

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.10
RUN set -x \
	&& buildDeps=' \
		unzip \
		ca-certificates \
		dirmngr \
		wget \
		xz-utils \
		gpg \
	' \
	&& apt-get update && apt-get install -y --no-install-recommends $buildDeps \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true

# install ffmpeg
#ENV FFMPEG_URL 'http://nas.oldiy.top/%E5%B7%A5%E5%85%B7/ffmpeg-release-amd64-static.tar.xz'
ENV FFMPEG_URL 'https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz'
RUN : \
	&& mkdir -p /tmp/ffmpeg \
	&& cd /tmp/ffmpeg \
	&& wget -O ffmpeg.tar.xz "$FFMPEG_URL" \
	&& tar -xf ffmpeg.tar.xz -C . --strip-components 1 \
	&& cp ffmpeg ffprobe qt-faststart /usr/bin \
	&& cd .. \
	&& rm -fr /tmp/ffmpeg

# install youtube-dl-webui
ENV YOUTUBE_DL_WEBUI_SOURCE /usr/src/youtube_dl_webui
WORKDIR $YOUTUBE_DL_WEBUI_SOURCE

RUN : \
	&& pip3 install --no-cache-dir youtube-dl flask \
	&& wget -O youtube-dl-webui.zip https://github.com/aikunzhe/youtubedl-webui/archive/0.3.zip \
	
	&& unzip youtube-dl-webui.zip \
	&& cd youtubedl-webui*/ \
	&& cp -r ./* $YOUTUBE_DL_WEBUI_SOURCE/ \
	&& ln -s $YOUTUBE_DL_WEBUI_SOURCE/example_config.json /etc/youtube-dl-webui.json \
	&& cd .. && rm -rf youtubedl-webui* \
	&& apt-get purge -y --auto-remove wget unzip dirmngr \
	&& rm -fr /var/lib/apt/lists/*

COPY docker-entrypoint.sh /usr/local/bin
COPY default_config.json /config.json

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 5555

VOLUME ["/youtube_dl"]

CMD ["python3", "-m", "youtube_dl_webui"]
