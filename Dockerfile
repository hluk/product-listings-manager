FROM centos:8
LABEL \
    name="product-listings-manager" \
    vendor="product-listings-manager developers" \
    license="MIT" \
    build-date=""

WORKDIR /src

RUN yum install -y epel-release \
    && yum -y update \
    && yum -y install \
        python3-flask \
        python3-gunicorn \
        python3-koji \
        python3-pip \
        python3-sqlalchemy

COPY . /tmp/code
RUN cd /tmp/code \
    && pip3 install \
        flask-restful==0.3.7 \
        flask-sqlalchemy==2.3.2 \
    && pip3 install . --no-deps \
    && yum -y clean all \
    && rm -rf /var/cache/yum \
    && rm -rf /tmp/*

ARG cacert_url
RUN if [ -n "$cacert_url" ]; then \
        cd /etc/pki/ca-trust/source/anchors \
        && curl -O --insecure $cacert_url \
        && update-ca-trust extract; \
    fi

USER 1001
EXPOSE 5000

CMD [ \
    "/usr/bin/gunicorn-3", \
    "--workers=8", \
    "--bind=0.0.0.0:5000", \
    "--access-logfile=-", \
    "--enable-stdio-inheritance", \
    "product_listings_manager.wsgi" \
    ]
