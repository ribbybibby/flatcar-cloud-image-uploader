FROM microsoft/azure-cli

RUN apk add jq && \
    apk add go --update-cache --repository http://dl-3.alpinelinux.org/alpine/edge/community/ --allow-untrusted

WORKDIR /usr/src

RUN go get -u golang.org/x/lint/golint && \
    wget https://github.com/microsoft/azure-vhd-utils/archive/master.zip && \
    unzip master.zip && \
    rm master.zip

WORKDIR /usr/src/azure-vhd-utils-master

ENV PATH="/root/go/bin:${PATH}"
RUN make && \
    cp /usr/src/azure-vhd-utils-master/azure-vhd-utils /usr/local/bin/azure-vhd-utils

COPY ./upload_image.sh /usr/local/bin/upload_images.sh

RUN chmod +x /usr/local/bin/upload_images.sh

ENTRYPOINT [ "/usr/local/bin/upload_images.sh" ]
