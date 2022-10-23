FROM ubuntu:20.04
ENV TZ=Asia/Shanghai \
    DEBIAN_FRONTEND=noninteractive

ADD . /app

RUN  echo "deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse" > /etc/apt/sources.list \
    && echo "deb-src http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb-src http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse" >>/etc/apt/sources.list \
    && echo "deb-src http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse" >>/etc/apt/sources.list \
    && echo "deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse" >>/etc/apt/sources.list \
    && echo "deb-src http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse" >>/etc/apt/sources.list \
    && echo "deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security main restricted universe multiverse" >>/etc/apt/sources.list \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime  && echo 'Asia/Shanghai' > /etc/timezone\
    && apt update && apt install git python3 npm make curl wget -y  \
    && mkdir /usr/include/nlohmann/ && cd /usr/include/nlohmann/ && wget https://github.com/nlohmann/json/releases/download/v3.10.5/json.hpp \
    && npm config set registry http://registry.npm.taobao.org && npm install -g node-gyp \
    && apt-get clean && rm -rf /var/lib/apt/lists/* 


RUN curl -s https://install.zerotier.com | bash \
    && cd /opt && git clone -v https://ghproxy.com/https://github.com/key-networks/ztncui.git --depth 1 \
    && cd /opt && git clone -v https://ghproxy.com/https://github.com/zerotier/ZeroTierOne.git --depth 1 \
    && cd /opt/ztncui/src \
    && npm install \
    && cp -pv ./etc/default.passwd ./etc/passwd \
    && echo 'HTTP_PORT=3443' >.env \
    && echo 'NODE_ENV=production' >>.env \
    && echo 'HTTP_ALL_INTERFACES=true' >>.env 

RUN cd /var/lib/zerotier-one && zerotier-idtool initmoon identity.public >moon.json \
    && cd /app/patch && python3 patch.py \
    && cd /var/lib/zerotier-one && zerotier-idtool genmoon moon.json && mkdir moons.d && cp ./*.moon ./moons.d \
    && cd /opt/ZeroTierOne/attic/world/ && sh build.sh \
    && sleep 5s \
    && cd /opt/ZeroTierOne/attic/world/ && ./mkworld \
    && mkdir /app/bin -p && cp world.bin /app/bin/planet \
    && service zerotier-one restart

WORKDIR /app/
CMD /bin/sh -c "zerotier-one -d; cd /opt/ztncui/src;npm start"
