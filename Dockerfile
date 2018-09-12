FROM debian:stretch
MAINTAINER Odoo S.A. <info@odoo.com>

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN set -x; \
        apt-get update \
        && apt-get install -y --no-install-recommends \
            ca-certificates \
            curl \
            node-less \
            python3-pip \
            python3-setuptools \
            python3-renderpm \
            libssl1.0-dev \
            xz-utils \
            python3-watchdog \
            git \
        && curl -o wkhtmltox.tar.xz -SL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz \
        && echo '3f923f425d345940089e44c1466f6408b9619562 wkhtmltox.tar.xz' | sha1sum -c - \
        && tar xvf wkhtmltox.tar.xz \
        && cp wkhtmltox/lib/* /usr/local/lib/ \
        && cp wkhtmltox/bin/* /usr/local/bin/ \
        && cp -r wkhtmltox/share/man/man1 /usr/local/share/man/ \
        && easy_install https://github.com/timotheus/ebaysdk-python/archive/master.zip \
        && pip install ptvsd==3.0.0 pudb wdb

# Debug Env
ENV PUDB_RDB_HOST=0.0.0.0 \
	PUDB_RDB_PORT=6899 \
	UNACCENT=true \
	WAIT_DB=true \
	WDB_NO_BROWSER_AUTO_OPEN=True \
	WDB_SOCKET_SERVER=wdb \
	WDB_WEB_PORT=1984 \
    WDB_WEB_SERVER=localhost

# Install Odoo
ENV ODOO_VERSION 11.0
ENV ODOO_RELEASE 20180808
RUN set -x; \
        curl -o odoo.deb -SL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
        && echo 'a48d588b76fd642ac9e1af63a38e4d87ee20531a odoo.deb' | sha1sum -c - \
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
        && mkdir -p /opt/odoo/addons/l10n_es \
        && git clone -b 10.0 https://github.com/OCA/l10n-spain.git /opt/odoo/addons/l10n_es \
        && mkdir -p /opt/odoo/addons/partner-contact \
        && git clone -b 10.0 https://github.com/OCA/partner-contact.git /opt/odoo/addons/partner-contact \
        && mkdir -p /opt/odoo/addons/delivery-carrier \
        && git clone -b 10.0 https://github.com/OCA/delivery-carrier.git /opt/odoo/addons/delivery-carrier \
        && mkdir -p /opt/odoo/addons/sale-workflow \
        && git clone -b 10.0 https://github.com/OCA/sale-workflow.git /opt/odoo/addons/sale-workflow \
        && mkdir -p /opt/odoo/addons/product-attribute \
        && git clone -b 10.0 https://github.com/OCA/product-attribute.git /opt/odoo/addons/product-attribute \
        && git clone -b 10.0-product_dimension https://github.com/gurneyalex/product-attribute.git /tmp/product_attribute \
        && rm -R /opt/odoo/addons/product-attribute/product_dimensions \
        && mv /tmp/product_attribute/product_dimensions /opt/odoo/addons/product-attribute \
        && rm -R /tmp/product_attribute \
        && git clone -b release/10.0/SMD-216-product_multi_image https://github.com/LasLabs/product-attribute.git /tmp/product_attribute \
        && rm -R /opt/odoo/addons/product-attribute/product_multi_image \
        && mv /tmp/product_attribute/product_multi_image/ /opt/odoo/addons/product-attribute \
        && rm -R /tmp/product_attribute \
	    && mkdir -p /opt/odoo/addons/server-tools \
        && git clone -b 10.0 https://github.com/OCA/server-tools.git /opt/odoo/addons/server-tools \
        && mkdir -p /opt/odoo/addons/bank-payment \
        && git clone -b 10.0 https://github.com/OCA/bank-payment.git /opt/odoo/addons/bank-payment \
        && git clone -b 10.0 https://github.com/OCA/web.git /opt/odoo/addons/web \
        && apt-get -y purge git

# Copy entrypoint script and Odoo configuration file
RUN pip3 install num2words xlwt
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/
RUN chown odoo /etc/odoo/odoo.conf

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN mkdir -p /mnt/extra-addons \
        && chown -R odoo /mnt/extra-addons
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8071

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]