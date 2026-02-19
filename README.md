# AWS 3層Webアプリケーション ポートフォリオ

[![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white)](https://flask.palletsprojects.com/)
[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com/)

## 📌 概要

AWS上にEC2、RDS、ALBを使用した**3層構成のTODO管理アプリケーション**を構築しました。
インフラは**Terraform**でコード化し、再現可能な構成になっています。

**🎯 このポートフォリオの目的**
- AWS実務スキルの可視化
- VPC設計・セキュリティ設計の理解を証明
- IaC（Infrastructure as Code）の実践
- 転職活動でのアピール材料

---

## 🏗️ システムアーキテクチャ

```mermaid
graph TB
    subgraph Internet["🌐 インターネット"]
        User["👤 ユーザー"]
    end

    subgraph AWS["☁️ AWS Cloud"]
        IGW["🚪 Internet Gateway"]

        subgraph VPC["VPC (10.0.0.0/16)"]
            subgraph AZ1["ap-northeast-1a"]
                subgraph PublicSubnet1a["📱 Public Subnet 1a<br/>(10.0.1.0/24)"]
                    ALB1["⚖️ ALB<br/>(Target)"]
                    EC2_1a["🖥️ EC2-Web-1a<br/>Nginx + Flask<br/>Port: 5000"]
                end

                subgraph PrivateSubnet1a["🔒 Private Subnet 1a<br/>(10.0.11.0/24)"]
                    RDS_Primary["🗄️ RDS Primary<br/>MySQL 8.0"]
                end
            end

            subgraph AZ2["ap-northeast-1c"]
                subgraph PublicSubnet1c["📱 Public Subnet 1c<br/>(10.0.2.0/24)"]
                    ALB2["⚖️ ALB<br/>(Target)"]
                    NAT["🔀 NAT Gateway"]
                end

                subgraph PrivateSubnet1c["🔒 Private Subnet 1c<br/>(10.0.12.0/24)"]
                    RDS_Standby["🗄️ RDS Standby<br/>MySQL 8.0"]
                end
            end
        end
    end

    User -->|HTTP:80| IGW
    IGW -->|Route| ALB1
    IGW -->|Route| ALB2
    ALB1 -->|HTTP:5000| EC2_1a
    ALB2 -->|HTTP:5000| EC2_1a
    EC2_1a -->|MySQL:3306| RDS_Primary
    RDS_Primary -.->|Replication| RDS_Standby

    style VPC fill:#FF9900,stroke:#232F3E,stroke-width:3px,color:#fff
    style PublicSubnet1a fill:#7AA116,stroke:#232F3E,stroke-width:2px
    style PublicSubnet1c fill:#7AA116,stroke:#232F3E,stroke-width:2px
    style PrivateSubnet1a fill:#3F8624,stroke:#232F3E,stroke-width:2px
    style PrivateSubnet1c fill:#3F8624,stroke:#232F3E,stroke-width:2px
    style EC2_1a fill:#FF9900,stroke:#232F3E,stroke-width:2px
    style RDS_Primary fill:#527FFF,stroke:#232F3E,stroke-width:2px
    style RDS_Standby fill:#527FFF,stroke:#232F3E,stroke-width:2px
    style ALB1 fill:#8C4FFF,stroke:#232F3E,stroke-width:2px
    style ALB2 fill:#8C4FFF,stroke:#232F3E,stroke-width:2px
```

> 📊 **詳細な構成図**: `docs/architecture.png` を参照

---

## 🎯 設計のポイント

### 1. 3層アーキテクチャ
- **プレゼンテーション層**: ALB（Application Load Balancer）
- **アプリケーション層**: EC2（Nginx + Flask）
- **データベース層**: RDS（MySQL Single-AZ）

### 2. 高可用性設計
- 複数のAvailability Zone（1a, 1c）に分散配置
- ALBによる負荷分散とヘルスチェック

### 3. セキュリティ設計
- RDSをプライベートサブネットに配置（インターネットから隔離）
- セキュリティグループで最小権限の原則を適用
- NATゲートウェイ経由でプライベートサブネットからのアウトバウンド通信

### 4. 運用性
- TerraformによるIaC化（インフラの再現性・バージョン管理）

---

## 🛠️ 技術スタック

| カテゴリ | 技術 |
|--------|------|
| クラウド | AWS (VPC, EC2, RDS, ALB, NAT Gateway, Internet Gateway) |
| OS | Amazon Linux 2023 |
| 言語 | Python 3.11 |
| フレームワーク | Flask 3.0 |
| Webサーバー | Nginx 1.24 |
| データベース | MySQL 8.0 |
| IaC | Terraform 1.7 |
| バージョン管理 | Git / GitHub |

---

## 📂 ディレクトリ構成

```
aws-3tier-portfolio/
├── README.md                    # このファイル
├── docs/                        # ドキュメント・図
│   ├── architecture.png         # 詳細構成図
│   └── screenshots/             # 動作画面
├── app/                         # Flaskアプリケーション
│   ├── app.py                   # メインアプリ
│   ├── templates/
│   │   └── index.html           # フロントエンド
│   ├── requirements.txt         # Python依存関係
│   └── config.py                # 設定ファイル
├── terraform/                   # インフラコード
│   ├── main.tf                  # メイン設定
│   ├── variables.tf             # 変数定義
│   ├── outputs.tf               # 出力値
│   ├── vpc.tf                   # VPC設定
│   ├── security_groups.tf       # セキュリティグループ
│   ├── ec2.tf                   # EC2設定
│   ├── rds.tf                   # RDS設定
│   └── alb.tf                   # ALB設定
└── scripts/                     # デプロイ・セットアップスクリプト
    ├── setup_ec2.sh             # EC2初期セットアップ
    └── deploy_app.sh            # アプリデプロイ
```

---

## 🚀 セットアップ手順

### 前提条件
- AWSアカウント（無料枠推奨）
- Terraform 1.7以上インストール済み
- AWS CLI設定済み（`aws configure`）
- SSH鍵ペア作成済み

### 1. リポジトリクローン

```bash
git clone https://github.com/[your-username]/aws-3tier-portfolio.git
cd aws-3tier-portfolio
```

### 2. Terraformで環境構築

```bash
cd terraform

# 初期化
terraform init

# tfvars ファイル作成（.gitignore対象）
cat > terraform.tfvars <<EOF
myip        = "$(curl -s ifconfig.me)/32"
key_name    = "your-key-pair-name"
db_password = "YourStrongPassword123!"
EOF

# 実行計画確認
terraform plan

# リソース作成（約10分）
terraform apply

# 出力値（ALBのDNS名など）を確認
terraform output
```

### 3. アプリケーションデプロイ

```bash
# EC2にSSH接続
ssh -i ~/.ssh/portfolio-key.pem ec2-user@<EC2-Public-IP>

# リポジトリクローン
git clone https://github.com/[your-username]/aws-3tier-portfolio.git
cd aws-3tier-portfolio/app

# 依存関係インストール
pip3 install -r requirements.txt

# 環境変数設定
export DB_HOST=<RDS-Endpoint>
export DB_USER=admin
export DB_PASS=<your-password>
export DB_NAME=todo_db

# アプリ起動
python3 app.py
```

### 4. 動作確認

```bash
# ALBのDNS名でアクセス
http://<ALB-DNS-Name>
```

---

## 🔐 セキュリティ設計

### セキュリティグループ設計

#### SG-ALB（Application Load Balancer用）
| タイプ | プロトコル | ポート | 送信元 |
|------|----------|------|------|
| インバウンド | HTTP | 80 | 0.0.0.0/0 |
| インバウンド | HTTPS | 443 | 0.0.0.0/0 |

#### SG-EC2（Webサーバー用）
| タイプ | プロトコル | ポート | 送信元 |
|------|----------|------|------|
| インバウンド | SSH | 22 | マイIP |
| インバウンド | カスタムTCP | 5000 | SG-ALB |

#### SG-RDS（データベース用）
| タイプ | プロトコル | ポート | 送信元 |
|------|----------|------|------|
| インバウンド | MySQL | 3306 | SG-EC2 |

---

## 💰 コスト見積もり（月間）

| サービス | スペック | 月額（USD） | 無料枠 |
|--------|--------|-----------|------|
| EC2 | t2.micro | $0 | 750時間/月 |
| RDS | db.t3.micro (Single-AZ) | $0 | 750時間/月 |
| ALB | - | ~$16 | なし |
| NAT Gateway | - | ~$32 | なし |
| **合計** | | **~$48** | |

> 💡 **コスト削減のコツ**: 学習後は `terraform destroy` で全削除

---

## 📈 今後の改善・拡張案

- [ ] Auto Scaling: EC2の自動スケーリング実装
- [ ] CloudFront: CDN配信で高速化
- [ ] Route 53: 独自ドメイン設定
- [ ] CI/CD: GitHub Actions でデプロイ自動化
- [ ] コンテナ化: ECS/Fargate への移行
- [ ] 監視強化: CloudWatch Logs, Alarms 設定
- [ ] バックアップ: RDS自動バックアップ設定
- [ ] WAF: AWS WAFでセキュリティ強化
- [ ] SSL/TLS: ACMで証明書発行、HTTPS化

---

## 📄 ライセンス

MIT License

---

## 👤 作成者

**藤原優性**

- 💼 職歴: エンジニア派遣営業（6ヶ月）、パートナーSier営業（現職）
- 🎓 資格: AWS SAA / SAP、CCNA、宅地建物取引士
- 📚 学習予定: LPIC Level 1、Oracle SQL Silver
- 🎯 目標: クラウドエンジニアとして上流工程に携わる

---

⭐ このリポジトリが参考になったら、Starをお願いします！
