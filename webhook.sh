#!/bin/bash

LOG_FILE="/var/log/certbot-renew.log"

# 判断日志文件是否存在，不存在则创建
if [ ! -f "$LOG_FILE" ]; then
    touch $LOG_FILE
fi

CERT_PATH="$RENEWED_LINEAGE/fullchain.pem"
KEY_PATH="$RENEWED_LINEAGE/privkey.pem"

if [ -f "$CERT_PATH" ] && [ -f "$KEY_PATH" ]; then
    CERT_CONTENT=$(cat "$CERT_PATH")
    KEY_CONTENT=$(cat "$KEY_PATH")

    # 判断是否有 webhook 地址
    if [ -z "$WEBHOOK_URL" ]; then
        echo "未设置 WEBHOOK_URL 环境变量，无法发送证书内容到 webhook。" >> $LOG_FILE
        exit 1
    fi
    
    if [ -n "$ENCRYPT_KEY" ]; then
        echo "对证书内容进行加密..." >> $LOG_FILE
        IV=$(openssl rand -base64 32 | md5) # 生成一个随机的16字节初始化向量 (IV)
        KEY=$ENCRYPT_KEY

        if ! ENCRYPTED_CERT_CONTENT=$(echo "$CERT_CONTENT" | openssl enc -aes-256-cbc -K "$KEY" -iv "$IV" -a -nosalt); then
            echo "Failed to encrypt certificate content" >> $LOG_FILE
            exit 1
        fi

        if ! ENCRYPTED_KEY_CONTENT=$(echo "$KEY_CONTENT" | openssl enc -aes-256-cbc -K "$KEY" -iv "$IV" -a -nosalt); then
            echo "Failed to encrypt key content" >> $LOG_FILE
            exit 1
        fi

        echo "发送加密的证书内容到 webhook..." >> $LOG_FILE
        if ! curl -X POST --data-urlencode "cert=$ENCRYPTED_CERT_CONTENT" --data-urlencode "key=$ENCRYPTED_KEY_CONTENT" --data-urlencode "iv=$IV" "$WEBHOOK_URL" >> $LOG_FILE 2>&1; then
            echo "Failed to send encrypted certificate content to webhook" >> $LOG_FILE
            exit 1
        fi

    else
        echo "发送未加密的证书内容到 webhook..." >> $LOG_FILE
        if ! curl -X POST --data-urlencode "cert=$CERT_CONTENT" --data-urlencode "key=$KEY_CONTENT" "$WEBHOOK_URL" >> $LOG_FILE 2>&1; then
            echo "Failed to send unencrypted certificate content to webhook" >> $LOG_FILE
            exit 1
        fi
    fi

else
    echo "未找到证书文件，无法发送到 webhook。" >> $LOG_FILE
fi
