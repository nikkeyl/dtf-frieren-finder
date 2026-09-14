#!/bin/sh

set -eu

API_BASE="https://api.dtf.ru/v2.10"
SUBSITE_URI="/lx_ix"
TAG="#иногдафрирен"
TMP_JSON="dtf-lxix.json"
TARGET_DIR="frieren_photos"

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required to parse DTF JSON" >&2
    exit 1
fi

cleanup() {
    rm -f "$TMP_JSON"
}

trap cleanup 0 1 2 15

mkdir -p "$TARGET_DIR"

encoded_subsite_uri="$(printf '%s' "$SUBSITE_URI" | jq -sRr @uri)"

curl -fsSL --retry 2 \
    -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)" \
    "$API_BASE/subsite?uri=$encoded_subsite_uri" -o "$TMP_JSON"

SUBSITE_ID="$(jq -er '.result.id' "$TMP_JSON")"
cursor=""

while :; do
    if [ -n "$cursor" ]; then
        encoded_cursor="$(printf '%s' "$cursor" | jq -sRr @uri)"
        timeline_url="$API_BASE/timeline?subsitesIds=$SUBSITE_ID&cursor=$encoded_cursor&sorting=new"
    else
        timeline_url="$API_BASE/timeline?subsitesIds=$SUBSITE_ID&sorting=new"
    fi

    curl -fsSL --retry 2 \
        -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)" \
        "$timeline_url" -o "$TMP_JSON"

    result="$(jq -c --arg tag "$TAG" '
        [
            .result.items[]?.data
            | select(any(.blocks[]? | .. | strings; contains($tag)))
            | {
                found: true,
                uuids: [
                    .blocks[]?
                    | ..
                    | objects
                    | select(.type? == "image")
                    | .data.uuid?
                    | select(type == "string")
                ] | unique
            }
        ][0] // {found: false, uuids: []}
    ' "$TMP_JSON")"

    found="$(printf '%s' "$result" | jq -r '.found')"
    if [ "$found" = "true" ]; then
        printf '%s' "$result" |
            jq -r '.uuids[]? | "https://leonardo.osnova.io/\(.)"' |
            while IFS= read -r url; do
                [ -n "$url" ] || continue

                filename="$(basename "$url").jpg"
                curl -fsSL --retry 2 "$url" -o "$TARGET_DIR/$filename"
            done
        break
    fi

    next_cursor="$(jq -r '.result.cursor // empty' "$TMP_JSON")"
    if [ -z "$next_cursor" ] || [ "$next_cursor" = "$cursor" ]; then
        break
    fi

    cursor="$next_cursor"
done
