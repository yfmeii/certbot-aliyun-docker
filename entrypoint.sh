#!/bin/bash

echo "启动入口脚本..."

# 配置阿里云 CLI
if ! aliyun configure set --access-key-id "$ALIYUN_ACCESS_KEY_ID" --access-key-secret "$ALIYUN_ACCESS_KEY_SECRET" --region "cn-hangzhou"; then
    echo "Failed to configure Aliyun CLI"
    exit 1
fi

LOG_FILE="/var/log/certbot-renew.log"

# 判断日志文件是否存在，不存在则创建
if [ ! -f "$LOG_FILE" ]; then
    touch $LOG_FILE
fi

# 添加 CertBot 续订任务到 crontab
if ! crontab -l | grep -q "0 2 * * * /usr/local/bin/get_cert.sh renew >> $LOG_FILE 2>&1"; then
    echo "将 CertBot 续订任务添加到 crontab..." >> $LOG_FILE
    if ! echo "0 2 * * * /usr/local/bin/get_cert.sh renew >> $LOG_FILE 2>&1" | crontab -; then
        echo "Failed to add CertBot renew task to crontab"
        exit 1
    fi
fi

/usr/local/bin/get_cert.sh >> $LOG_FILE 2>&1

# 启动 crond 服务并保持容器运行，同时输出日志
echo "启动 crond 服务..." >> $LOG_FILE
crond

# 实时输出日志
tail -f $LOG_FILE
