FROM ubuntu:18.04
MAINTAINER Matthew Mattox matthew.mattox@rancher.com
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -yq --no-install-recommends \
apt-utils \
apache2 \
libapache2-mod-php7.2 \
php7.2-cli \
php7.2-json \
php7.2-curl \
openssl \
nano \
locales \
wget \
curl \
&& apt-get clean && rm -rf /var/lib/apt/lists/*

##Installing kubectl
#RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && mv kubectl /bin/kubectl && chmod +x /bin/kubectl
ADD kubectl /bin/
RUN chmod +x /bin/kubectl

RUN a2enmod rewrite expires
RUN echo "ServerName localhost" | tee /etc/apache2/conf-available/servername.conf
RUN a2enconf servername

##Configure Apache
COPY apache.conf /etc/apache2/sites-available/
RUN a2dissite 000-default
RUN a2ensite apache.conf
RUN ln -sf /proc/self/fd/1 /var/log/apache2/access.log && \
    ln -sf /proc/self/fd/1 /var/log/apache2/error.log

COPY public_html /var/www/src/
RUN mkdir -p /var/www/src/bin/

ADD *.sh /var/www/src/bin/
RUN chmod +x /var/www/src/bin/*.sh

EXPOSE 80

WORKDIR /var/www/src
CMD apachectl -D FOREGROUND
