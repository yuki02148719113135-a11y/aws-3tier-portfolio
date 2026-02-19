resource "aws_instance" "web" {
  ami                    = "ami-094dc5cf74289dfbc" # Amazon Linux 2023 (ap-northeast-1)
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_1a.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y nginx python3 python3-pip git

    # Flask アプリ用ディレクトリ
    mkdir -p /opt/app
    cd /opt/app

    # 依存関係インストール
    pip3 install Flask==3.0.0 PyMySQL==1.1.0 python-dotenv==1.0.0

    # Nginx をリバースプロキシとして設定
    cat > /etc/nginx/conf.d/app.conf <<'NGINX'
    server {
        listen 80;
        location / {
            proxy_pass http://127.0.0.1:5000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
    NGINX

    systemctl enable --now nginx
    EOF

  tags = {
    Name = "${local.name_prefix}-ec2-web"
  }
}
