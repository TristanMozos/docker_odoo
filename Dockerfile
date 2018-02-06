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
	    python-dev \
            git \
        && curl -o wkhtmltox.deb -SL http://nightly.odoo.com/extra/wkhtmltox-0.12.1.2_linux-jessie-amd64.deb \
        && echo '40e8b906de658a2221b15e4e8cd82565a47d7ee8 wkhtmltox.deb' | sha1sum -c - \
        && dpkg --force-depends -i wkhtmltox.deb \
        && apt-get -y install -f --no-install-recommends \
        && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false npm \
        && rm -rf /var/lib/apt/lists/* wkhtmltox.deb \
        && pip install psycogreen==1.0 \ 
        && pip install unicodecsv \
	&& pip install pysftp \
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
ENV ODOO_VERSION 10.0
ENV ODOO_RELEASE 20170815
RUN set -x; \
        curl -o odoo.deb -SL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
        && echo '08d21e6419a72be7a3ad784df7a6fc8a46bbe7d9 odoo.deb' | sha1sum -c - \
        && dpkg --force-depends -i odoo.deb \
        && apt-get update \
        && apt-get -y install -f --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* odoo.deb \
        && rm -R /usr/lib/python2.7/dist-packages/odoo/addons/l10n_es \
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
	&& mkdir -p /opt/odoo/addons/server-tools \
        && git clone -b 10.0 https://github.com/OCA/server-tools.git /opt/odoo/addons/server-tools \
        && pip install git+https://github.com/TristanMozos/python-amazon-mws.git \
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

# Expose Odoo services
EXPOSE 8069 8071

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
USER odoo
ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
