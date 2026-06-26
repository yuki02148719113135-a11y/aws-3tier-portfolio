output "alb_dns_name" {
  description = "ALB の DNS 名（アプリへのアクセス URL）"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ec2_public_ip" {
  description = "EC2 のパブリック IP（SSH 接続用）"
  value       = aws_instance.web.public_ip
}

output "rds_endpoint" {
  description = "RDS エンドポイント（DB 接続先）"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}
