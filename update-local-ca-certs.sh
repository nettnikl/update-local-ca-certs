#!/bin/sh

DOMAIN="${DOMAIN}"
CERT_DIR="/certs"
CERTSTORE_PATH="/certs-out/ca-certificates.crt"

WEBHOOK_URL="${WEBHOOK_URL}"
WEBHOOK_METHOD="${WEBHOOK_METHOD:-POST}"
WEBHOOK_CONTENTTYPE="${WEBHOOK_CONTENTTYPE:-application/json}"

call_webhook() {
    if command -v curl > /dev/null 2>&1; then
        curl -X "${WEBHOOK_METHOD}" -H "Content-Type: ${WEBHOOK_CONTENTTYPE}" "${WEBHOOK_URL}"
    elif command -v wget > /dev/null 2>&1; then
        wget -O- --method="${WEBHOOK_METHOD}" --header="Content-Type: ${WEBHOOK_CONTENTTYPE}" "${WEBHOOK_URL}"
    else
        exit 1
    fi
}

/usr/local/bin/generate-certs-from-env.sh

echo "Updating chain.pem"
cat "$CERT_DIR/$DOMAIN/cert.pem" "$CERT_DIR/servers.pem" > "$CERT_DIR/$DOMAIN/chain.pem"

echo "Updating fullchain.pem"
cat "$CERT_DIR/$DOMAIN/cert.pem" "$CERT_DIR/servers.pem" "$CERT_DIR/cacert.pem" > "$CERT_DIR/$DOMAIN/fullchain.pem"

echo "Updating certstore at $CERTSTORE_PATH"
cat /etc/ssl/certs/ca-certificates.crt "$CERT_DIR/cacert.pem" > "$CERTSTORE_PATH"

echo "Calling webhook"
call_webhook

if [ "$1" = "--now" ]; then
    exit 0
fi

inotifywait -e close_write,moved_to,create -m "$CERT_DIR" |
while read -r filename; do
    if [ "$filename" = "cert.pem" ] || [ "$filename" = "servers.pem" ] || [ "$filename" = "cacert.pem" ]; then
        echo "Change to $filename detected, updating chain.pem"
        cat "$CERT_DIR/$DOMAIN/cert.pem" "$CERT_DIR/servers.pem" > "$CERT_DIR/$DOMAIN/chain.pem"

        echo "Change to $filename detected, updating fullchain.pem"
        cat "$CERT_DIR/$DOMAIN/cert.pem" "$CERT_DIR/servers.pem" "$CERT_DIR/cacert.pem" > "$CERT_DIR/$DOMAIN/fullchain.pem"

        if [ -n "$WEBHOOK_URL" ]; then
            echo "Change to $filename detected, calling webhook"
            call_webhook
        fi
    fi

    if [ "$filename" = "cacert.pem" ]; then
        echo "Change to $filename detected, updating cert store"
        cat "/etc/ssl/certs/ca-certificates.crt" "$CERT_DIR/cacert.pem" > "$CERTSTORE_PATH"
    fi
done
