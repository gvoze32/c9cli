# Cloud9 server
# A lot inspired by https://hub.docker.com/r/sapk/cloud9

FROM node:lts-slim
LABEL maintainer="Syafa Adena <adena@adena.my.id>"

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y locales \
 && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
 && locale-gen en_US.UTF-8 \
 && dpkg-reconfigure locales \
 && /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LC_CTYPE=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

RUN buildDeps='make build-essential g++ gcc python2.7' && softDeps="tmux git zip" \
 && apt-get update && apt-get upgrade -y \
 && apt-get install wget unzip -y \
 && apt-get install -y $buildDeps $softDeps --no-install-recommends \
 && npm install -g forever && npm cache clean --force \
 && wget https://github.com/c9/core/archive/refs/heads/master.zip && unzip master.zip && cd core-master \
# && git clone --depth=5 https://github.com/c9/core.git /cloud9 && cd /cloud9 \
 && scripts/install-sdk.sh \
 && apt-get purge -y --auto-remove $buildDeps \
 && apt-get autoremove -y && apt-get autoclean -y && apt-get clean -y \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
 && npm cache clean --force
# && git reset --hard
 
VOLUME /workspace
EXPOSE 8181 
ENTRYPOINT ["forever", "/cloud9/server.js", "-w", "/workspace", "--listen", "0.0.0.0"]

CMD ["--auth","c9:c9"]
