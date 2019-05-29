FROM google/cloud-sdk

RUN apt-get update && apt-get install -y wget

COPY ./upload_image.sh /usr/local/bin/upload_images.sh

RUN chmod +x /usr/local/bin/upload_images.sh

ENTRYPOINT [ "/usr/local/bin/upload_images.sh" ]
