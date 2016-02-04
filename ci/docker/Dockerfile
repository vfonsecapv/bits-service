FROM concourse/concourse-ci

RUN apt-get update
RUN apt-get install -y wget curl zip

RUN wget https://github.com/cloudfoundry-incubator/spiff/releases/download/v1.0.7/spiff_linux_amd64.zip
RUN unzip spiff_linux_amd64.zip && mv spiff /usr/local/bin/
