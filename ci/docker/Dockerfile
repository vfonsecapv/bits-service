FROM ubuntu:15.10

RUN apt-get update && \
    apt-get -y install git zip unzip wget curl software-properties-common \
        libxml2-dev libxslt-dev libcurl4-openssl-dev \
        build-essential zlib1g-dev libssl-dev libreadline6-dev libyaml-dev && \
        apt-get clean -y && \
        apt-get autoremove -y && \
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN add-apt-repository ppa:brightbox/ruby-ng && \
    apt-get update && \
    apt-get -y install ruby2.2 ruby2.2-dev && \
    apt-get clean -y && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN gem install bundler --no-rdoc --no-ri && \
    gem install bosh_cli -v 1.3177.0 --no-rdoc --no-ri

RUN wget https://github.com/cloudfoundry-incubator/spiff/releases/download/v1.0.7/spiff_linux_amd64.zip && \
    unzip spiff_linux_amd64.zip && mv spiff /usr/local/bin/ && rm spiff_linux_amd64.zip
