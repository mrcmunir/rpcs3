#!/bin/sh -ex

ARTIFACT_DIR="$BUILD_ARTIFACTSTAGINGDIRECTORY"

# Función para escapar texto para JSON
escape_json() {
    local text="$1"
    # Escapar comillas, backslashes, newlines, etc.
    text="${text//\\/\\\\}"
    text="${text//\"/\\\"}"
    text="${text//$'\n'/\\n}"
    text="${text//$'\r'/\\r}"
    text="${text//$'\t'/\\t}"
    echo "$text"
}

generate_post_data()
{
    body=$(cat GitHubReleaseMessage.txt)
    body_escaped=$(escape_json "$body")
    
    cat <<EOF
{
    "tag_name": "build-${BUILD_SOURCEVERSION}",
    "target_commitish": "${UPLOAD_COMMIT_HASH}",
    "name": "${AVVER}",
    "body": "$body_escaped",
    "draft": false,
    "prerelease": false
}
EOF
}

# Debug: mostrar qué se va a enviar
echo "=== JSON que se enviará a GitHub ==="
generate_post_data
echo "=== Fin del JSON ==="

curl -fsS \
    -H "Authorization: token ${RPCS3_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    --data "$(generate_post_data)" "https://api.github.com/repos/$UPLOAD_REPO_FULL_NAME/releases" >> release.json

cat release.json
id=$(grep '"id"' release.json | cut -d ':' -f2 | head -n1 | awk '{$1=$1;print}')
id=${id%?}
echo "${id:?}"

upload_file()
{
    curl -fsS \
        -H "Authorization: token ${RPCS3_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Content-Type: application/octet-stream" \
        --data-binary @"$2"/"$3" \
        "https://uploads.github.com/repos/$UPLOAD_REPO_FULL_NAME/releases/$1/assets?name=$3"
}

for file in "$ARTIFACT_DIR"/*; do
    name=$(basename "$file")
    upload_file "$id" "$ARTIFACT_DIR" "$name"
done
