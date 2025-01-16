FROM debian:latest

ENV CERT_DIR=/certs

COPY update-local-ca-certs.sh generate-certs-from-env.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/update-local-ca-certs.sh /usr/local/bin/generate-certs-from-env.sh

ENTRYPOINT ["/usr/local/bin/update-local-ca-certs.sh"]
