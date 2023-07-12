FROM google/cloud-sdk:437.0.1

RUN mkdir -p /root/local/ssl && \
    mkdir -p /root/build/openssl && \
    curl -L -o /tmp/openssl.tar.gz https://www.openssl.org/source/old/1.1.0/openssl-1.1.0l.tar.gz && \
    tar xzvf /tmp/openssl.tar.gz \
      -C /root/build/openssl/ \
      --strip-components 1 && \
    rm /tmp/openssl.tar.gz

COPY gcp-openssl.patch /root/build
WORKDIR /root/build
RUN cat gcp-openssl.patch | patch -d . -p0
COPY build.sh /root/build/openssl
WORKDIR /root/build/openssl
RUN chmod +x build.sh && ./build.sh

COPY openssl.sh /root/local/bin
RUN chmod u+x /root/local/bin/openssl.sh
RUN ln -s /root/local/bin/openssl.sh /usr/local/bin/openssl.sh
RUN rm -rf /root/build

RUN apt update && apt install -y bsdmainutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /root
CMD /bin/bash
