FROM debian:bullseye-slim
MAINTAINER Odoo S.A. <info@odoo.com>

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Retrieve the target architecture to install the correct wkhtmltopdf package
ARG TARGETARCH

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        dirmngr \
        fonts-noto-cjk \
        gnupg \
        libssl-dev \
        node-less \
        npm \
        python3-magic \
		git \
		procps \
		net-tools \
		inotify-tools \
		pkg-config \
		libxml2-dev \
		libxmlsec1-dev \
		libxmlsec1-openssl \
		gcc \
		make \
		vim \
		sudo \
		zip \
		unzip \
		libffi-dev \
		libbz2-dev \
		zlib1g-dev \
		liblzma-dev \
		libjpeg-dev \
		libcurl4-openssl-dev \
		xmlsec1 \
        python3-num2words \
        python3-odf \
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
		openssh-client \
		libdmtx0b \
        xz-utils && \
    if [ -z "${TARGETARCH}" ]; then \
        TARGETARCH="$(dpkg --print-architecture)"; \
    fi; \
    WKHTMLTOPDF_ARCH=${TARGETARCH} && \
    case ${TARGETARCH} in \
    "amd64") WKHTMLTOPDF_ARCH=amd64 && WKHTMLTOPDF_SHA=9df8dd7b1e99782f1cfa19aca665969bbd9cc159  ;; \
    "arm64")  WKHTMLTOPDF_SHA=58c84db46b11ba0e14abb77a32324b1c257f1f22  ;; \
    "ppc64le" | "ppc64el") WKHTMLTOPDF_ARCH=ppc64el && WKHTMLTOPDF_SHA=7ed8f6dcedf5345a3dd4eeb58dc89704d862f9cd  ;; \
    esac \
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bullseye_${WKHTMLTOPDF_ARCH}.deb \
    && echo ${WKHTMLTOPDF_SHA} wkhtmltox.deb | sha1sum -c - \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o rustup.sh && sh rustup.sh -y
RUN pip3 install --upgrade pip
RUN pip3 install wheel && pip3 install rust && pip3 install asn1crypto && pip3 install importlib-metadata && pip3 install --ignore-installed git+https://github.com/OCA/openupgradelib.git@master && pip3 install codicefiscale && pip3 install opencv-python-headless && pip3 install pylibdmtx  && pip3 install debugpy && pip3 install astor && pip3 install base45 && pip3 install sortedcontainers && pip3 install pikepdf && pip3 install openpyxl && pip3 install ftputil && pip3 install pysftp && pip3 install jwt && pip install pdfkit && pip3 install 'signxml==3.2.2'
# install latest postgresql-client
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
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
ENV ODOO_VERSION 16.0
ARG ODOO_RELEASE=20250819
ARG ODOO_SHA=6e4d8446d4a6af7c147f84a5b3d824a7ddaec5c5
RUN curl -o odoo.deb -sSL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
    && echo "${ODOO_SHA} odoo.deb" | sha1sum -c - \
    && apt-get update \
    && apt-get -y install --no-install-recommends ./odoo.deb \
    && rm -rf /var/lib/apt/lists/* odoo.deb

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/

# Set permissions and Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN chown odoo /etc/odoo/odoo.conf \
    && mkdir -p /mnt/extra-addons \
    && chown -R odoo /mnt/extra-addons
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8071 8072 8888

#Fixup lxml version
RUN pip3 uninstall -y cryptography
RUN pip3 install 'cryptography==36.0.2'
RUN pip3 uninstall -y pyOpenSSL
RUN pip3 install 'pyOpenSSL==21.0.0'
RUN pip3 uninstall -y xmlsec
RUN pip3 install 'xmlsec==1.3.12'
RUN pip3 uninstall -y lxml
RUN pip3 install 'lxml==4.8.0'
RUN pip3 uninstall -y xmlschema
RUN pip3 install 'xmlschema==3.4.3'
RUN pip3 install 'bokeh==3.1.1'
RUN pip3 uninstall -y paramiko
RUN pip3 install 'paramiko==3.5.1'
RUN pip3 install 'openai'
# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py
COPY neutralize.py /usr/local/bin/neutralize.py

# Set default user when running the container
RUN /usr/bin/chsh -s /bin/bash root
RUN /usr/bin/chsh -s /bin/bash odoo
ENV SHELL /bin/bash
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]

