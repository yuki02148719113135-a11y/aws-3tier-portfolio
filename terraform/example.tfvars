# このファイルをコピーして terraform.tfvars を作成してください
# terraform.tfvars は .gitignore で除外されています

env         = "portfolio"
myip        = "YOUR_IP/32"        # curl ifconfig.me で確認
key_name    = "your-key-pair"     # AWS コンソールで作成した鍵ペア名
db_username = "admin"
db_password = "YourStrongPassword123!"  # 実際には強力なパスワードを設定
