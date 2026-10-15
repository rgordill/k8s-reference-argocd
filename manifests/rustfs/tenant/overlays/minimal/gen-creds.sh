#!/usr/bin/env bash
# Generate random tenant credentials for rustfs minimal overlay
# Run this before applying the kustomization

set -euo pipefail

CREDS_FILE="$(dirname "$0")/creds.env"

# Generate random credentials
ACCESS_KEY=$(openssl rand -hex 16)
SECRET_KEY=$(openssl rand -hex 32)

cat > "$CREDS_FILE" <<EOF
accesskey=$ACCESS_KEY
secretkey=$SECRET_KEY
EOF

echo "Generated $CREDS_FILE"
echo "  accesskey=$ACCESS_KEY"
echo "  secretkey=$SECRET_KEY"
echo ""
echo "Now run: kustomize build . | kubectl apply -f -"