#!/bin/bash

LOG_FILE="/var/log/certbot-renew.log"

# 判断日志文件是否存在，不存在则创建
if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
fi

if [ "$USE_TEST_ENV" = "true" ]; then
    CERTBOT_FLAGS="--test-cert"
else
    CERTBOT_FLAGS=""
fi

# 申请或续订证书的函数
renew_cert() {
    echo "检查是否存在证书目录"
    if [ ! -d "/etc/letsencrypt/live" ]; then
        echo "未找到现有证书目录，请求新的证书..." >> $LOG_FILE
        if ! certbot certonly -d "$DOMAIN" --manual --preferred-challenges dns --manual-auth-hook "alidns" --manual-cleanup-hook "alidns clean" --email "$EMAIL" --agree-tos $CERTBOT_FLAGS --deploy-hook /usr/local/bin/webhook.sh; then
            echo "Failed to request new certificate" >> $LOG_FILE
            exit 1
        fi
    else
        echo "找到现有证书目录，正在续订..." >> $LOG_FILE
        if ! certbot renew --manual --preferred-challenges dns --manual-auth-hook "alidns" --manual-cleanup-hook "alidns clean" --email "$EMAIL" --agree-tos $CERTBOT_FLAGS --deploy-hook /usr/local/bin/webhook.sh; then
            echo "Failed to renew certificate" >> $LOG_FILE
            exit 1
        fi
    fi
}


if [ "$1" = "renew" ]; then
    echo "执行 renew_cert 函数..." >> $LOG_FILE
    renew_cert >> $LOG_FILE 2>&1
else

    # 检查并申请证书
    if [ ! -d "/etc/letsencrypt/live" ]; then
            renew_cert >> $LOG_FILE 2>&1
    else
            echo "已存在证书目录，跳过 renew_cert." >> $LOG_FILE
    fi
    
fi
