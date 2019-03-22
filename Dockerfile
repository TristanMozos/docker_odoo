FROM debian:jessie
MAINTAINER Halltic eSolutions S.L. 

FROM debian:jessie
LABEL maintainer="Odoo S.A. <info@odoo.com>"

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN set -x; \
        apt-get update \
        && apt-get install -y --no-install-recommends \
            ca-certificates \
            curl \
            dirmngr \
            node-less \
            python-gevent \
            python-ldap \
            python-pip \
            python-qrcode \
            python-renderpm \
            python-support \
            python-vobject \
            python-watchdog \
            python-lxml \
            git \
        && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.jessie_amd64.deb \
        && echo '4d104ff338dc2d2083457b3b1e9baab8ddf14202 wkhtmltox.deb' | sha1sum -c - \
        && dpkg --force-depends -i wkhtmltox.deb \
        && apt-get -y install -f --no-install-recommends \
        && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false npm \
        && rm -rf /var/lib/apt/lists/* wkhtmltox.deb \
        && pip install --upgrade pip \
        && pip install psycogreen==1.0 \
        && pip install boto3==1.4.2 \
        && pip install botocore==1.4.1 \
        && pip install unicodecsv \
	    && pip install unidecode \
	    && pip install cachetools==2.1.0 \
	    && pip install requests \
	    && pip install --upgrade setuptools

# install latest postgresql-client
RUN set -x; \
        echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' > etc/apt/sources.list.d/pgdg.list \
        && export GNUPGHOME="$(mktemp -d)" \
        && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
        && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
        && gpg --armor --export "${repokey}" | apt-key add - \
        && rm -rf "$GNUPGHOME" \
        && apt-get update  \
        && apt-get install -y postgresql-client \
        && rm -rf /var/lib/apt/lists/*


# Install Odoo
ENV ODOO_VERSION 10.0
ARG ODOO_RELEASE=20190128
ARG ODOO_SHA=673bb5e45c006c9a822a0ca1a7d19989c03151ad
RUN set -x; \
        curl -o odoo.deb -sSL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
        && echo "${ODOO_SHA} odoo.deb" | sha1sum -c - \
        && dpkg --force-depends -i odoo.deb \
        && apt-get update \
        && apt-get -y install -f --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* odoo.deb \
        && apt-get update \
        && apt-get -y install -f --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* odoo.deb \
        && rm -R /usr/lib/python2.7/dist-packages/odoo/addons/l10n_es \
        && git clone -b 10.0 https://github.com/OCA/queue.git /tmp/queue \
        && mv /tmp/queue/queue_job /usr/lib/python2.7/dist-packages/odoo/addons/ \
        && rm -R /tmp/queue \
        && git clone -b 10.0 https://github.com/OCA/connector.git /tmp/connector \
        && mv /tmp/connector/component /usr/lib/python2.7/dist-packages/odoo/addons/ \
        && mv /tmp/connector/component_event /usr/lib/python2.7/dist-packages/odoo/addons/ \
        && mv /tmp/connector/connector_base_product /usr/lib/python2.7/dist-packages/odoo/addons/ \
        && mv /tmp/connector/connector /usr/lib/python2.7/dist-packages/odoo/addons/ \
        && rm -R /tmp/connector \
        && git clone -b 10.0 https://github.com/OCA/connector-ecommerce.git /tmp/connector_ecommerce \
        && mv /tmp/connector_ecommerce/connector_ecommerce /usr/lib/python2.7/dist-packages/odoo/addons/ \
        && rm -R /tmp/connector_ecommerce \
        && easy_install https://github.com/timotheus/ebaysdk-python/archive/master.zip \
        && apt-get -y purge git

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/
RUN chown odoo /etc/odoo/odoo.conf

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN mkdir -p /mnt/extra-addons \
        && chown -R odoo /mnt/extra-addons
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Fix an warehouse location error
RUN rm /usr/lib/python2.7/dist-packages/odoo/addons/stock/models/stock_warehouse.py
COPY ./stock_warehouse.py /usr/lib/python2.7/dist-packages/odoo/addons/stock/models/

# Expose Odoo services
EXPOSE 8069 8071

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
