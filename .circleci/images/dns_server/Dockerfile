FROM ubuntu:bionic

# Fetch and install dnsmasq
# RUN apk update && apk --no-cache add bind

RUN apt-get update -y && apt-get install -y bind9

# Configure BIND9
COPY named.conf /etc/bind/named.conf

# Start BIND9 in foreground
CMD ["/usr/sbin/named", "-f"]