FROM alpine:3.14

# 安装必要的软件包
RUN apk add --no-cache wget tar bash curl jq certbot bind-tools openssl || { echo "Failed to install necessary packages"; exit 1; }

# 安装阿里云 CLI
RUN wget https://aliyuncli.alicdn.com/aliyun-cli-linux-latest-amd64.tgz && \
    tar xzvf aliyun-cli-linux-latest-amd64.tgz && \
    mv aliyun /usr/local/bin && \
    rm aliyun-cli-linux-latest-amd64.tgz || { echo "Failed to install Aliyun CLI"; exit 1; }

# 安装 Certbot DNS Aliyun Hook
RUN wget https://cdn.jsdelivr.net/gh/justjavac/certbot-dns-aliyun@main/alidns.sh && \
    mv alidns.sh /usr/local/bin/alidns && \
    chmod +x /usr/local/bin/alidns || { echo "Failed to install Certbot DNS Aliyun Hook"; exit 1; }

# 复制 entrypoint 脚本
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 复制 get_cert.sh 脚本
COPY get_cert.sh /usr/local/bin/get_cert.sh
RUN chmod +x /usr/local/bin/get_cert.sh

# 复制 webhook 脚本
COPY webhook.sh /usr/local/bin/webhook.sh
RUN chmod +x /usr/local/bin/webhook.sh

# 确保 crond 目录存在
RUN mkdir -p /var/spool/cron/crontabs && touch /var/spool/cron/crontabs/root

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
