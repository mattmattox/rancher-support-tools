FROM ubuntu:18.04
MAINTAINER Matthew Mattox matthew.mattox@rancher.com
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -yq --no-install-recommends \
apt-utils \
conntrack \
sysstat \
iptables \
wget \
curl \
iputils-ping \
ca-certificates \
git \
dnsutils \
jq \
nano \
&& apt-get clean && rm -rf /var/lib/apt/lists/*

##Installing kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && mv kubectl /bin/kubectl && chmod +x /bin/kubectl

##Install Docker client
RUN curl -fsSL https://get.docker.com -o get-docker.sh && sh ./get-docker.sh

##Setup main process
ADD *.sh /root/
RUN chmod +x /root/*.sh
CMD /root/run.sh
