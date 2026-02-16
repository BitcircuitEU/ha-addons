FROM ghcr.io/netbootxyz/netbootxyz:latest

RUN apk add --no-cache bash

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
