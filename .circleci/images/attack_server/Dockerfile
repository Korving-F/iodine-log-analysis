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

# Create testfile to be copied over
WORKDIR /root
RUN lorem -p 10000 > test-file

# Start wrapper script with Iodine and sshd
# Iodine Daemon (-4 ipv4, -c Disable Client IP/port check on each request, -f tunnel IP, domain, -P password)
CMD ["iodined", "-4", "-c", "-f", "10.0.0.1", "example.attack", "-P", "abc123"]
#COPY wrapper-script.sh wrapper-script.sh
#RUN chmod +x wrapper-script.sh
#CMD ["./wrapper-script.sh"]

# Expose DNS port
EXPOSE 53/udp
