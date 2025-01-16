#!/bin/sh
CERT_DIR="${CERT_DIR:-./certs}"

mkdir -p "$CERT_DIR"

if [ -n "${INTERMEDIATE_CERT}" ]; then
    INTERMEDIATE_CERT=$(echo "${INTERMEDIATE_CERT}" | base64 -d)
    echo "${INTERMEDIATE_CERT}" > "$CERT_DIR/servers.pem"
    echo "Intermediate Certificate from \$INTERMEDIATE_CERT b64 decoded and written to $CERT_DIR/servers.pem"
fi

if [ -n "${ROOT_CERT}" ]; then
    ROOT_CERT=$(echo "${ROOT_CERT}" | base64 -d)
    echo "${ROOT_CERT}" > "$CERT_DIR/cacert.pem"
    echo "CA Certificate from \$ROOT_CERT b64 decoded and written to $CERT_DIR/cacert.pem"
fi

env | while IFS='=' read -r var value; do
    base_name="${var%_KEY}"
    case "$var" in
        *CERT)
            output_file="${CERT_DIR}/${base_name}.lan/cert.pem"
            echo "$value" | base64 -d > "${output_file}"
            echo "Certificate from \$$var b64 decoded and written to ${output_file}"
            cat "${CERT_DIR}/${base_name}.lan/cert.pem" "$CERT_DIR/servers.pem" > "${CERT_DIR}/${base_name}.lan/chain.pem"
            cat "${CERT_DIR}/${base_name}.lan/cert.pem" "$CERT_DIR/servers.pem" "$CERT_DIR/cacert.pem" > "${CERT_DIR}/${base_name}.lan/fullchain.pem"
            ;;
        *KEY)
            output_file="${CERT_DIR}/${base_name}.lan/cert.key.pem"
            echo "$value" | base64 -d > "${output_file}"
            echo "Certificate key from \$$var b64 decoded and written to ${output_file}"
            ;;
    esac
done
