ARG VARIANT="11"
ARG BASE_IMAGE=debian

FROM ${BASE_IMAGE}:${VARIANT}

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt update -y && \
    apt install -o Dpkg::Options::='--force-confnew' --allow-downgrades --allow-remove-essential --allow-change-held-packages -fuy -y \
        build-essential python \
        curl gpg xz-utils \
        libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 \
        libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 \
        libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 \
        libx11-6 libx11-xcb1 libxcb1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 libnss3 \
        ca-certificates fonts-liberation libasound2 libatk-bridge2.0-0 libatk1.0-0 libatspi2.0-0 libc6 libcairo2 libcups2 libcurl4 libdbus-1-3 libexpat1 libgbm1 libgcc1 libglib2.0-0 libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 libx11-6 libxcb1 libxcomposite1 libxdamage1 libxext6 libxfixes3 libxkbcommon0 libxrandr2 libxshmfence1 wget xdg-utils \
        chromium fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 fonts-roboto

ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Clear cache
RUN apt-get -qq -y autoremove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ARG NODE_VERSION=18.7.0

RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" && \ 
    case "${dpkgArch##*-}" in \
        amd64) ARCH='x64';; \
        ppc64el) ARCH='ppc64le';; \
        s390x) ARCH='s390x';; \
        arm64) ARCH='arm64';; \
        armhf) ARCH='armv7l';; \
        i386) ARCH='x86';; \
    *) echo "unsupported architecture"; exit 1 ;; \
    esac && \
    set -ex && \
    curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" && \
    tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner && \
    rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" && \
    ln -s /usr/local/bin/node /usr/local/bin/nodejs

RUN mkdir -p /code

WORKDIR /code

COPY . /code

RUN npm install && \
    npm run build

CMD HOST="0.0.0.0" npm start