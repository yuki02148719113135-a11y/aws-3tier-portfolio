#!/bin/bash
# EC2 初期セットアップスクリプト
# 用途: EC2 インスタンスに初めて SSH 接続した際に実行
# 実行方法: bash setup_ec2.sh

set -e

echo "=== EC2 初期セットアップ開始 ==="

# パッケージ更新
dnf update -y

# 必要パッケージインストール
dnf install -y nginx python3 python3-pip git

# Python パッケージインストール
pip3 install Flask==3.0.0 PyMySQL==1.1.0 python-dotenv==1.0.0

# アプリディレクトリ作成
mkdir -p /opt/app

# Nginx 設定
cat > /etc/nginx/conf.d/app.conf <<'NGINX'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
NGINX

# デフォルト設定を無効化
rm -f /etc/nginx/conf.d/default.conf

# Nginx 有効化・起動
systemctl enable --now nginx

echo "=== セットアップ完了 ==="
echo "次のステップ: scripts/deploy_app.sh を実行してください"
