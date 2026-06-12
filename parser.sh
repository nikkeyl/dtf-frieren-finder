#!/bin/bash

URL="https://dtf.ru/lx_ix"
TAG="#иногдафрирен"
TMP_HTML="dtf-lxix.html"
TMP_POST="dtf-post-full.html"
TARGET_DIR="frieren_photos"

echo "気ままなエルフを探しています..."

rm -f "$TMP_HTML"
mkdir -p "$TARGET_DIR"

curl -s -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" "$URL" -o "$TMP_HTML"

if [ ! -s "$TMP_HTML" ]; then
    echo "ネットの守護者が私たちの前に扉を閉ざしたのか、それともこの場所の魔法が尽きたのか…"

    exit 1
fi

post_index=0

grep -oP '(?s)<article.*?</article>' "$TMP_HTML" | while read -r post; do
    post_index=$((post_index + 1))

    if echo "$post" | grep -q "$TAG"; then
        echo "--------------------------------------------------"
        echo "静かな喜びのひととき。この物語で #$post_index 番目の $TAG を見つけました"
        echo "--------------------------------------------------"

        if echo "$post" | grep -q 'content__read-more'; then
            echo "スポイラーの裏に隠された宝があります。全文を取得します..."

            post_url=$(echo "$post" | grep -oP 'href="(https://dtf\.ru/[^"]+)"' | grep -oP 'https://[^"]+' | head -1)

            if [ -n "$post_url" ]; then
                curl -s -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" "$post_url" -o "$TMP_POST"
                
                source_html="$TMP_POST"
            else
                echo "URLの抽出に失敗しました。元のコンテンツを使用します。"

                source_html=""
            fi
        else
            source_html=""
        fi

        if [ -n "$source_html" ]; then
            urls=$(grep -o 'https://leonardo\.osnova\.io/[^" ]*' "$source_html" |
                sed 's|/-/scale_crop/.*||' |
                awk '!seen[$0]++'
            )

            rm -f "$source_html"
        else
            urls=$(echo "$post" |
                grep -o 'https://leonardo\.osnova\.io/[^" ]*' |
                sed 's|/-/scale_crop/.*||' |
                awk '!seen[$0]++'
            )
        fi

        if [ -n "$urls" ]; then
            echo "そこには $(echo "$urls" | wc -l) 個の温もりの欠片が隠されています。見てみましょう："
            echo "$urls"

            for url in $urls; do
                filename=$(basename "$url").jpg

                curl -s -L "$url" -o "$TARGET_DIR/$filename"
            done

            echo "これらの宝物を丁寧に荷造りして保存しました。"
        else
            echo "最後まで旅をしましたが、'$TAG' は見つかりませんでした。でも大丈夫。旅そのものが報酬です。もう少し進みましょう。"
        fi

        rm -f "$TMP_HTML"

        exit 0
    fi
done

rm -f "$TMP_HTML"

rm -f "$TMP_HTML"
