FROM ubuntu:16.04

ENV PATH /root/.local/bin:$PATH

ENV KUBE_PACKAGES_URL "https://storage.googleapis.com/kubernetes-release/release"

RUN apt-get update \
    && apt-get install -y curl dnsutils python python-pip wget \
    && pip install --upgrade --user awscli \
    && pip install --upgrade --user virtualenv 

RUN curl -LO ${KUBE_PACKAGES_URL}/$(curl -s ${KUBE_PACKAGES_URL}/stable.txt)/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl \
    && mv ./kubectl /usr/local/bin/kubectl

RUN wget https://github.com/kubernetes/kops/releases/download/v1.5.3/kops-linux-amd64 \
    && chmod +x kops-linux-amd64 \
    && mv kops-linux-amd64 /usr/local/bin/kops

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

