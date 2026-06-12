#!/bin/bash

URL="https://dtf.ru/lx_ix"
TAG="#иногдафрирен"
TMP_HTML="dtf-lxix.html"
TARGET_DIR="frieren_photos"

rm -f "$TMP_HTML"
mkdir -p "$TARGET_DIR"

curl -s -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" "$URL" -o "$TMP_HTML"

if [ ! -s "$TMP_HTML" ]; then
    exit 1
fi

post_index=0

grep -oP '(?s)<article.*?</article>' "$TMP_HTML" | while read -r post; do
    post_index=$((post_index + 1))

    if echo "$post" | grep -q "$TAG"; then
        urls=$(echo "$post" |
            grep -o 'https://leonardo\.osnova\.io/[^" ]*' |
            sed 's|/-/scale_crop/.*||' |
            awk '!seen[$0]++'
        )

        if [ -n "$urls" ]; then
            for url in $urls; do
                filename=$(basename "$url").jpg

                curl -s -L "$url" -o "$TARGET_DIR/$filename"
            done
        fi

        rm -f "$TMP_HTML"

        exit 0
    fi
done

rm -f "$TMP_HTML"
