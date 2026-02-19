#!/bin/bash
# アプリデプロイスクリプト
# 用途: Flask アプリを EC2 にデプロイ（またはアップデート）
# 実行方法: bash deploy_app.sh
# 前提: 環境変数 DB_HOST, DB_USER, DB_PASS, DB_NAME が設定されていること

set -e

APP_DIR="/opt/app"
REPO_URL="https://github.com/yuki02148719113135-a11y/aws-3tier-portfolio.git"
SERVICE_FILE="/etc/systemd/system/flask-app.service"

echo "=== Flask アプリデプロイ開始 ==="

# リポジトリのクローン or アップデート
if [ -d "$APP_DIR/.git" ]; then
    echo "リポジトリを更新中..."
    git -C "$APP_DIR" pull
else
    echo "リポジトリをクローン中..."
    git clone "$REPO_URL" "$APP_DIR"
fi

cd "$APP_DIR/app"
pip3 install -r requirements.txt

# systemd サービス設定
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Flask TODO App
After=network.target

[Service]
User=ec2-user
WorkingDirectory=$APP_DIR/app
ExecStart=/usr/bin/python3 app.py
Restart=always
Environment=DB_HOST=${DB_HOST}
Environment=DB_USER=${DB_USER}
Environment=DB_PASS=${DB_PASS}
Environment=DB_NAME=${DB_NAME:-todo_db}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable flask-app
systemctl restart flask-app

echo "=== デプロイ完了 ==="
echo "ステータス確認: systemctl status flask-app"
