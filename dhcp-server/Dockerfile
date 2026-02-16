ARG BUILD_FROM
FROM ${BUILD_FROM}

RUN apk add --no-cache \
    bash \
    jq \
    python3 \
    py3-flask \
    py3-gunicorn \
    dnsmasq \
    && true

COPY run.sh /run.sh
COPY app.py /app.py
COPY dnsmasq-control.sh /usr/local/bin/dnsmasq-control
COPY templates /templates
COPY static /static

RUN chmod +x /run.sh /usr/local/bin/dnsmasq-control

CMD ["/run.sh"]
