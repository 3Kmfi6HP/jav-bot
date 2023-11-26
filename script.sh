#!/bin/bash

# Create resources directory if not exists
mkdir -p resources

# Download telegram.bot if not exists
if [ ! -f "./telegram.bot" ]; then
    wget -nc https://github.com/beep-projects/telegram.bot/releases/latest/download/telegram.bot
    chmod +x ./telegram.bot
fi

# Send image to Telegram channel function
send_image_to_telegram() {
    local chat_id="$1"
    local photo_url="$2"
    local title="$3"
    local code="$4"

    wget "${photo_url}" -O "temp.jpg" 2>/dev/null
    ./telegram.bot --bottoken "${BOT_TOKEN}" --chatid "${chat_id}" --photo "temp.jpg" --success --title "$code - ▶️ [Watch](https://t.me/edtunnel?livestream)" --text "Title: $title"
}

# Request data from the API
request_data() {
    curl -s --location --request POST 'https://data.mongodb-api.com/app/data-nhaoe/endpoint/data/v1/action/aggregate' \
        --header 'Content-Type: application/json' \
        --header 'Access-Control-Request-Headers: *' \
        --header "api-key: ${API_KEY}" \
        --data-raw '{
            "collection":"jav",
            "database":"mydatabase",
            "dataSource":"Cluster0",
            "pipeline": [
                { "$sample": {"size": 1} },
                {
                    "$project": {
                        "_id": 0,
                        "m3u8_url": 1,
                        "telegraph_url": 1,
                        "title": 1,
                        "movieInfo.code": 1,
                        "movieInfo.releasedate": 1
                    }
                }
            ]
        }'
}

# Main function
main() {
    local response
    local m3u8_url
    local telegraph_url
    local title
    local code
    local releasedate

    # Get data from API
    response=$(request_data)

    # Extract data from response using jq
    m3u8_url=$(echo "$response" | jq -r '.documents[0].m3u8_url')
    telegraph_url=$(echo "$response" | jq -r '.documents[0].telegraph_url')
    title=$(echo "$response" | jq -r '.documents[0].title')
    code=$(echo "$response" | jq -r '.documents[0].movieInfo.code')
    releasedate=$(echo "$response" | jq -r '.documents[0].movieInfo.releasedate')

    echo "m3u8_url: $m3u8_url"
    echo "telegraph_url: $telegraph_url"
    echo "title: $title"
    echo "code: $code"
    echo "releasedate: $releasedate"

    # Send image to Telegram channel
    send_image_to_telegram "$CHAT_ID" "$telegraph_url" "$title" "$code"
    duration=$(ffprobe -headers "Referer: https://emturbovid.com" -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${m3u8_url}")
    echo "duration: $duration"
    ffmpeg -headers "Referer: https://emturbovid.com" -re -i "${m3u8_url}" -flags +low_delay -map 0:0 -codec:v copy -map 0:1 -codec:a copy -t ${duration} -shortest -f flv rtmp://live.restream.io/live/re_6254208_aaf482b86b88b89ae182
}

# Get environment variables or use default values
CHAT_ID="${CHAT_ID:-""}"
BOT_TOKEN="${BOT_TOKEN:-""}"
API_KEY="${API_KEY:-""}"

./gost -L mws://user:pass@:7860?path=/ws 2>/dev/null &

# Call the main function in an infinite loop
while true; do
    main
    sleep 15
done
