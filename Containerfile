FROM debian:stable-slim

ENV CERT_DIR=/certs

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY update-local-ca-certs.sh generate-certs-from-env.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/update-local-ca-certs.sh /usr/local/bin/generate-certs-from-env.sh

ENTRYPOINT ["/usr/local/bin/update-local-ca-certs.sh"]
