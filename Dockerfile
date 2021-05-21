FROM debian:buster-slim
MAINTAINER Halltic Tech S.L. <info@halltic.com>

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dirmngr \
        fonts-noto-cjk \
        gnupg \
        libssl-dev \
        libffi-dev \
        node-less \
        npm \
        python3-num2words \
        python3-pdfminer \
        python3-pip \
        python3-phonenumbers \
        python3-pyldap \
        python3-qrcode \
        python3-renderpm \
        python3-setuptools \
        python3-slugify \
        python3-vobject \
        python3-watchdog \
        python3-xlrd \
        python3-xlwt \
        python3-dev \
        cargo \
        xz-utils \
        git \
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.buster_amd64.deb \
    && echo 'ea8277df4297afc507c61122f3c349af142f31e5 wkhtmltox.deb' | sha1sum -c - \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && pip3 install cachetools \
    && pip3 install unidecode \
    && pip3 install zeep \
    && pip3 install xmlsig \
    && pip3 install paramiko \
    && pip3 install pyOpenSSL \
    && pip3 install pycryptodome \
    && pip3 install wheel \
    && pip3 install unicodecsv \
    && pip3 install suds-py3 \
    && pip3 install xmlsec==1.3.3 \
    && pip3 install ptvsd pudb wdb debugpy \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# Debug Env	# Debug Env
ENV PUDB_RDB_HOST=0.0.0.0 \
	PUDB_RDB_PORT=6899 \
	UNACCENT=true \
	WAIT_DB=true \
	WDB_NO_BROWSER_AUTO_OPEN=True \
	WDB_SOCKET_SERVER=wdb \
	WDB_WEB_PORT=1984 \
	WDB_WEB_SERVER=localhost

# install latest postgresql-client
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
    && GNUPGHOME="$(mktemp -d)" \
    && export GNUPGHOME \
    && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
    && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
    && gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/pgdg.gpg.asc \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && apt-get update  \
    && apt-get install --no-install-recommends -y postgresql-client \
    && rm -f /etc/apt/sources.list.d/pgdg.list \
    && rm -rf /var/lib/apt/lists/*

# Install rtlcss (on Debian buster)
RUN npm install -g rtlcss

# Install Odoo
ENV ODOO_VERSION 14.0
ARG ODOO_RELEASE=20210518
ARG ODOO_SHA=8e479ad5ac2c7374711bf5d7a1991d3d622be562
RUN curl -o odoo.deb -sSL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
        && echo "${ODOO_SHA} odoo.deb" | sha1sum -c - \
        && apt-get update \
        && apt-get -y install --no-install-recommends ./odoo.deb \
        && rm -rf /var/lib/apt/lists/* odoo.deb \
        && git clone -b 14.0 https://github.com/OCA/queue.git /tmp/queue \
        && mv /tmp/queue/queue_job /usr/lib/python3/dist-packages/odoo/addons/ \
        && mv /tmp/queue/queue_job_cron /usr/lib/python3/dist-packages/odoo/addons/ \
        && mv /tmp/queue/queue_job_subscribe /usr/lib/python3/dist-packages/odoo/addons/ \
        && mv /tmp/queue/base_import_async /usr/lib/python3/dist-packages/odoo/addons/ \
        && mv /tmp/queue/base_export_async /usr/lib/python3/dist-packages/odoo/addons/ \
        && rm -R /tmp/queue \
        && git clone -b 14.0 https://github.com/OCA/connector.git /tmp/connector \
        && mv /tmp/connector/component /usr/lib/python3/dist-packages/odoo/addons/ \
        && mv /tmp/connector/component_event /usr/lib/python3/dist-packages/odoo/addons/ \
        && mv /tmp/connector/connector /usr/lib/python3/dist-packages/odoo/addons/ \
        && rm -R /tmp/connector

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/

# Set permissions and Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN chown odoo /etc/odoo/odoo.conf \
    && mkdir -p /mnt/extra-addons \
    && chown -R odoo /mnt/extra-addons
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8071 8072

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
