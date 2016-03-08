FROM dockercloud/haproxy:latest

# Install packages
RUN apt-get update && apt-get install -y --force-yes curl dnsutils runit

# Install PIP & awscli
RUN apt-get remove python-pip -y --force-yes
RUN curl -sL https://bootstrap.pypa.io/get-pip.py | python
RUN pip install 'awscli'

# Setup runit for HAProxy
RUN mkdir -p        /etc/service/haproxy
ADD ./haproxy.runit /etc/service/haproxy/run
RUN chmod +x        /etc/service/haproxy/run

# Setup runit for ddns
RUN mkdir -p            /etc/service/ddns
ADD ./update-route53.sh /etc/service/ddns/update-route53.sh
RUN chmod +x            /etc/service/ddns/update-route53.sh
ADD ./ddns.runit        /etc/service/ddns/run
RUN chmod +x            /etc/service/ddns/run


# Setup runit bootstrap
COPY runit_bootstrap /usr/sbin/runit_bootstrap
RUN chmod 755 /usr/sbin/runit_bootstrap

ENTRYPOINT ["/usr/sbin/runit_bootstrap"]