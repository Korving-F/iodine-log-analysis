FROM alpine:edge

# Fetch and install dnsmasq
RUN apk update && apk --no-cache add dnsmasq

#configure dnsmasq
RUN mkdir -p /etc/default/
RUN echo -e "ENABLED=1\nIGNORE_RESOLVCONF=yes" > /etc/default/dnsmasq
COPY dnsmasq.conf /etc/dnsmasq.conf

ENTRYPOINT ["dnsmasq","--no-daemon"]
