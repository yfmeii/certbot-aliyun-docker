## 使用阿里云 DNS 实现 Certbot 自动续签证书的 Docker 镜像

没上传到 Docker Hub，需要自行构建。


以下是 Docker 容器运行命令中使用的环境变量及其说明：

| 参数名                | 说明                                                | 示例值                       |
|-----------------------|-----------------------------------------------------|-----------------------------|
| ALIYUN_ACCESS_KEY_ID  | 阿里云访问密钥 ID                                    | your_access_key_id          |
| ALIYUN_ACCESS_KEY_SECRET | 阿里云访问密钥密钥                                | your_access_key_secret      |
| DOMAIN                | 需要申请或续订证书的域名                            | *.example.com             |
| EMAIL                 | 用于 Certbot 注册和恢复联系的电子邮件地址             | your_email@example.com      |
| USE_TEST_ENV          | 是否使用测试环境 | true 或 false               |
| WEBHOOK_URL           | 证书申请或更新完成后发送证书内容的 webhook 地址       | https://your-webhook-url.com |
| ENCRYPT_KEY          | 用于使用 webhook 时加密证书内容的密钥（可选）                       | your_encrypt_key           |

### 🌰 示例命令

```shell
docker run -d \
  -e ALIYUN_ACCESS_KEY_ID=your_access_key_id \
  -e ALIYUN_ACCESS_KEY_SECRET=your_access_key_secret \
  -e DOMAIN="*.example.com" \
  -e EMAIL="your_email@example.com" \
  -e USE_TEST_ENV=true \  # 或 false
  -e WEBHOOK_URL="https://your-webhook-url.com" \
  -e ENCRYPT_KEY="your_encrypt_key" \  # 可选
  -v /etc/letsencrypt:/etc/letsencrypt \
  certbot-aliyun-docker
```

#### 说明

- 请根据实际情况替换示例值。
- 如果不需要加密证书内容，可以省略 `ENCRYPT_KEY` 环境变量。
- 请确保在 `DOMAIN` 中使用正确的域名格式，例如 `*.example.com` 表示通配符域名。


### 🔗 Webhook 说明
本脚本在证书申请或更新完成后，将证书内容发送到指定的 `WEBHOOK_URL` 地址。如果设置了 `ENCRYPT_KEY`，证书内容会使用该密钥进行加密。详细说明如下：

#### 加密流程
如果设置了 `ENCRYPT_KEY`，脚本会：
1. 生成一个随机的16字节初始化向量（IV）。
2. 使用 AES-256-CBC 算法和提供的 `ENCRYPT_KEY` 对证书内容进行加密。
3. 通过 POST 请求将加密后的证书内容以及 IV 发送到指定的 `WEBHOOK_URL`。

#### 未加密传输
如果未设置 `ENCRYPT_KEY`，脚本会直接通过 POST 请求将未加密的证书内容发送到 `WEBHOOK_URL`。

#### POST 请求内容
- `cert`：证书内容（加密或未加密）。
- `key`：私钥内容（加密或未加密）。
- `iv`（如果设置了 `ENCRYPT_KEY`）：用于加密的初始化向量。

#### 注意事项
- 请确保 `WEBHOOK_URL` 已正确配置并可访问。
- 如果使用加密，请妥善保管 `ENCRYPT_KEY`，以便能够解密证书内容。
- 初始化向量（IV）是随机生成的，每次加密都会不同，因此发送到 webhook 的 IV 也需要用于解密。

#### 示例解密代码
以下是一个使用 Node.js 解密证书内容的示例代码：
```javascript
const crypto = require('crypto');

function decrypt(encryptedText, key, iv) {
  // 确保 key 和 iv 的位数正确
  const keyBuffer = Buffer.alloc(32);
  const ivBuffer = Buffer.alloc(16); 
  
  // 填充 key 和 iv
  Buffer.from(key, 'hex').copy(keyBuffer);
  Buffer.from(iv, 'hex').copy(ivBuffer);
  
  // 创建解密器
  const decipher = crypto.createDecipheriv('aes-256-cbc', keyBuffer, ivBuffer);
  let decrypted = decipher.update(encryptedText, 'base64', 'utf8');
  decrypted += decipher.final('utf8');
  
  return decrypted;
}
```

### ⚠️ 潜在问题和故障排除步骤

#### 1. 阿里云 CLI 配置失败
**问题描述**: 在配置阿里云 CLI 时可能会失败。
**解决方案**: 请检查 `ALIYUN_ACCESS_KEY_ID` 和 `ALIYUN_ACCESS_KEY_SECRET` 是否正确设置，并确保网络连接正常。

#### 2. Certbot 证书申请或续订失败
**问题描述**: 在申请或续订证书时可能会失败。
**解决方案**: 请检查 `DOMAIN` 和 `EMAIL` 是否正确设置，并确保 DNS 记录已正确配置。如果使用了 `--test-cert` 标志，请确保在生产环境中移除该标志。

#### 3. Webhook 发送失败
**问题描述**: 在发送证书内容到 webhook 时可能会失败。
**解决方案**: 请检查 `WEBHOOK_URL` 是否正确设置，并确保 webhook 服务可访问。如果使用了 `ENCRYPT_KEY`，请确保密钥正确设置。

#### 4. 加密或解密失败
**问题描述**: 在加密或解密证书内容时可能会失败。
**解决方案**: 请检查 `ENCRYPT_KEY` 是否正确设置，并确保密钥格式正确。如果问题仍然存在，请检查加密和解密代码是否正确实现。

### 📂 使用项目
https://github.com/justjavac/certbot-dns-aliyun
