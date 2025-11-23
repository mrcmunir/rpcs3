#!/bin/bash -ex

ARTIFACT_DIR="$BUILD_ARTIFACTSTAGINGDIRECTORY"

# ===== 1. Crear la release =====
create_release_payload() {
cat <<EOF
{
  "tag_name": "build-${AVVER}",
  "target_commitish": "${GITHUB_SHA}",
  "name": "RPCS3 Linux armv8.0 test- ${AVVER}",
  "body": "Build auto for armv8.0 linux.",
  "draft": false,
  "prerelease": false
}
EOF
}

# Crear release
curl -fsS \
    -H "Authorization: token ${RPCS3_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    --data "$(create_release_payload)" \
    "https://api.github.com/repos/${UPLOAD_REPO_FULL_NAME}/releases" \
    > release.json

# Sacar el ID de la release creada
id=$(grep '"id"' release.json | head -n 1 | cut -d ':' -f2 | tr -d ' ,')
echo "Release ID: $id"

# ===== 2. Subir los AppImage =====
upload_file() {
    curl -fsS \
      -H "Authorization: token ${RPCS3_TOKEN}" \
      -H "Accept: application/vnd.github+json" \
      -H "Content-Type: application/octet-stream" \
      --data-binary @"$1" \
      "https://uploads.github.com/repos/${UPLOAD_REPO_FULL_NAME}/releases/${id}/assets?name=$(basename "$1")"
}

for f in "$ARTIFACT_DIR"/*.AppImage; do
    echo "Subiendo: $f"
    upload_file "$f"
done
