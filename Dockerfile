FROM debian:jessie
MAINTAINER Halltic eSolutions S.L. 

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN set -x; \
        apt-get update \
        && apt-get install -y --no-install-recommends \
            ca-certificates \
            curl \
            node-less \
            python-gevent \
            python-pip \
            python-renderpm \
            python-support \
            python-watchdog \
            python-lxml \
            git \
        && curl -o wkhtmltox.deb -SL http://nightly.odoo.com/extra/wkhtmltox-0.12.1.2_linux-jessie-amd64.deb \
        && echo '40e8b906de658a2221b15e4e8cd82565a47d7ee8 wkhtmltox.deb' | sha1sum -c - \
        && dpkg --force-depends -i wkhtmltox.deb \
        && apt-get -y install -f --no-install-recommends \
        && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false npm \
        && rm -rf /var/lib/apt/lists/* wkhtmltox.deb \
        && pip install psycogreen==1.0 \
        && pip install unicodecsv \
	    && pip install unidecode \
	    && pip install cachetools \
	    && pip install requests \
	    && pip install --upgrade setuptools


# Install Odoo
ENV ODOO_VERSION 10.0
ENV ODOO_RELEASE 20180808
RUN set -x; \
        curl -o odoo.deb -SL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
        && echo '98736953010be3c578f4b9eb1c7e2c87da93a7bd odoo.deb' | sha1sum -c - \
        && dpkg --force-depends -i odoo.deb \
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
        && mkdir -p /opt/odoo/addons/l10n_es \
        && git clone -b 10.0 https://github.com/OCA/l10n-spain.git /opt/odoo/addons/l10n_es \
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
