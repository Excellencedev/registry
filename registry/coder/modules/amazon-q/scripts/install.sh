#!/bin/bash
set -o errexit
set -o pipefail

ARCH="$(uname -m)"
case "$ARCH" in
  "x86_64")
    BINARY_NAME="q-x86_64-linux.zip"
    ;;
  "aarch64"|"arm64")
    BINARY_NAME="q-aarch64-linux.zip"
    ;;
  *)
    echo "Error: Unsupported architecture: $ARCH. Amazon Q only supports x86_64 and arm64."
    exit 1
    ;;
esac

if [ "${ARG_INSTALL}" = "true" ]; then
  echo "Installing Amazon Q..."
  PREV_DIR="$PWD"
  TMP_DIR="$(mktemp -d)"
  cd "$TMP_DIR"

  Q_URL="https://desktop-release.q.us-east-1.amazonaws.com/${ARG_GOOSE_VERSION}/${BINARY_NAME}"
  echo "Downloading Amazon Q for $ARCH from $Q_URL..."
  curl --proto '=https' --tlsv1.2 -sSf "$Q_URL" -o "q.zip"
  unzip q.zip
  ./q/install.sh --no-confirm
  cd "$PREV_DIR"
  echo "Installed Amazon Q version: $(q --version)"
fi

# Create config directory
mkdir -p ~/.local/share/amazon-q

cat > ~/.local/share/amazon-q/config.yaml <<EOF
${ARG_GOOSE_CONFIG}
EOF

echo "Amazon Q configuration created."
