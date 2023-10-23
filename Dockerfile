FROM postgres:15

RUN apt-get update && \
    apt-get install -yy \
    bzip2 \
    curl \
    mcrypt \
    postgresql-client \
    unzip

RUN mkdir -p /tmp/awscli2-install && \
    cd /tmp/awscli2-install && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-`uname -m`.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf /tmp/awscli2-install

COPY ./run.sh /usr/local/bin/run.sh

RUN useradd user
USER user
WORKDIR /home/user

CMD ["/usr/local/bin/run.sh"]
