#!/bin/sh -ex

# Directorio donde están los artefactos (AppImage, etc.)
ARTIFACT_DIR="$BUILD_ARTIFACTSTAGINGDIRECTORY"

# Crear la release en GitHub
generate_post_data() {
    cat <<EOF
{
  "tag_name": "build-${BUILD_SOURCEVERSION}",
  "target_commitish": "${UPLOAD_COMMIT_HASH}",
  "name": "${AVVER}",
  "draft": false,
  "prerelease": false
}
EOF
}

# Crear la release y guardar la respuesta
curl -fsS \
    -H "Authorization: token ${RPCS3_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    --data "$(generate_post_data)" \
    "https://api.github.com/repos/$UPLOAD_REPO_FULL_NAME/releases" \
    > release.json

cat release.json

# Extraer el ID de la release recién creada
id=$(grep '"id"' release.json | head -n1 | awk -F: '{gsub(/[^0-9]/,"",$2); print $2}')
echo "Release ID: ${id:?}"

# Función para subir cada archivo
upload_file() {
    curl -fsS \
        -H "Authorization: token ${RPCS3_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Content-Type: application/octet-stream" \
        --data-binary @"$2"/"$3" \
        "https://uploads.github.com/repos/$UPLOAD_REPO_FULL_NAME/releases/$1/assets?name=$3"
}

# Subir todos los artefactos del directorio
for file in "$ARTIFACT_DIR"/*; do
    name=$(basename "$file")
    upload_file "$id" "$ARTIFACT_DIR" "$name"
done
