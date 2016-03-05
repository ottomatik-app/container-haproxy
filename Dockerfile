FROM dockercloud/haproxy:latest

# Install PIP
RUN apt-get update && apt-get install -y --force-yes curl dnsutils
RUN apt-get remove python-pip -y --force-yes
RUN curl -sL https://bootstrap.pypa.io/get-pip.py | python
RUN pip install 'awscli'

# Add init scripts
RUN mkdir -p             /etc/my_init.d
ADD ./update-route53.sh  /etc/my_init.d/01_update-route53.sh
RUN chmod +x             /etc/my_init.d/01_update-route53.sh

RUN echo "*/30 * * * * root sh /etc/my_init.d/01_update-route53.sh" >> /etc/crontab