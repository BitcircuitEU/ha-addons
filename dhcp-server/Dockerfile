ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:3.20
FROM ${BUILD_FROM}

RUN apk add --no-cache \
    bash \
    jq \
    python3 \
    py3-pip \
    dnsmasq \
    && pip3 install --no-cache-dir flask gunicorn

COPY run.sh /run.sh
COPY app.py /app.py
COPY dnsmasq-control.sh /usr/local/bin/dnsmasq-control
COPY templates /templates
COPY static /static

RUN chmod +x /run.sh /usr/local/bin/dnsmasq-control

CMD ["/run.sh"]
