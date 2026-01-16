# Start with empty ubuntu machine
FROM ubuntu:24.04

LABEL maintainer="Nicholas Myers"

# Setup correct environment variable
ENV HOME=/root

# Change to working directory
WORKDIR /opt

# To avoid having a prompt on tzdata setup during installation
ENV DEBIAN_FRONTEND=noninteractive

RUN chmod 1777 /tmp

RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa

# Install dependancies
RUN apt-get update && apt-get install -y \
    nginx \
    curl \
    git \
    vim \
    supervisor \
    python3.8 \
    python3.8-dev \
    python3.8-distutils \
    python3.8-venv \
    build-essential \
    tcl8.6 \
    wget \
    libgcrypt20-dev \
    zlib1g-dev \
    apt-transport-https \
    ca-certificates \
    lxc \
    iptables \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/TangoService/Tango/

# Install Docker from Docker Inc. repositories.
RUN curl -sSL https://get.docker.com/ -o get_docker.sh && sh get_docker.sh

# Install the magic wrapper.
ADD ./wrapdocker /usr/local/bin/wrapdocker
RUN chmod +x /usr/local/bin/wrapdocker

# Define additional metadata for our image.
VOLUME /var/lib/docker

WORKDIR /opt

# Create virtualenv to link dependancies
RUN python3.8 -m venv venv

WORKDIR /opt/TangoService/Tango

# Add in requirements
COPY requirements.txt .

# Install python dependancies
RUN /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install -r requirements.txt

# Move all code into Tango directory
COPY . .
RUN mkdir -p volumes

RUN mkdir -p /var/log/docker /var/log/supervisor /var/log/tango

# Move custom config file to proper location
RUN cp /opt/TangoService/Tango/deployment/config/nginx.conf /etc/nginx/nginx.conf
RUN cp /opt/TangoService/Tango/deployment/config/supervisord.conf /etc/supervisor/supervisord.conf

# Reload new config scripts
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]