FROM ubuntu:bionic

# Install dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y git make build-essential pkg-config zlib1g-dev net-tools openssh-server iputils-ping netcat dnsutils libtext-lorem-perl sshpass

# Setup ssh-server for testing (https://hub.docker.com/r/rastasheep/ubuntu-sshd/dockerfile)
RUN mkdir /var/run/sshd && \
    echo 'root:root' | chpasswd && \
    sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config && \
    mkdir /root/.ssh

# Clone - Make - Install Iodine (DNS Attack Tool)
WORKDIR /opt
RUN git clone https://github.com/yarrick/iodine.git
WORKDIR /opt/iodine
RUN make && \
    make install

# Start Iodine Client (-4 ipv4, -c force DNS over UDP, -f tunnel IP, domain, -P password, -r force DNS tunneling, remote server)
# CMD ["iodine", "-4", "-f", "-P", "abc123", "-Tsrv", "-Oraw", "-r", "172.18.0.4", "example.attack"]
CMD ["/usr/sbin/sshd","-D"]
