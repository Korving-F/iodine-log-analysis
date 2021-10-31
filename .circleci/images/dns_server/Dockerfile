FROM alpine:edge

# Fetch and install dnsmasq
RUN apk update && apk --no-cache add bind

# Configure BIND9
COPY named.conf /etc/bind/named.conf

# Start BIND9 in foreground
CMD ["named", "-g"]