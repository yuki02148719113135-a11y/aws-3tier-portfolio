# 構築ログ

AWS 3層Webアプリケーション ポートフォリオの構築作業記録。

---

## 2026/02/22（日）- VPCネットワーク基盤構築

### 作業概要

AWS 3層構成ポートフォリオの第1フェーズとして、VPCネットワーク基盤とセキュリティグループを構築。

**作業時間**: 約3時間（13:00-16:00）

### 実施した作業

#### 1. VPC作成

| 項目 | 設定値 |
|------|------|
| 名前 | portfolio-portfolio-vpc |
| CIDR | 10.0.0.0/16 |
| リージョン | ap-northeast-1（東京） |
| DNSホスト名 | 有効化 |
| DNSサポート | 有効化 |

#### 2. サブネット作成（4つ）

| サブネット名 | AZ | CIDR | タイプ |
|------------|-----|------|------|
| portfolio-portfolio-public-subnet-1a | ap-northeast-1a | 10.0.1.0/24 | パブリック |
| portfolio-portfolio-public-subnet-1c | ap-northeast-1c | 10.0.2.0/24 | パブリック |
| portfolio-portfolio-private-subnet-1a | ap-northeast-1a | 10.0.11.0/24 | プライベート |
| portfolio-portfolio-private-subnet-1c | ap-northeast-1c | 10.0.12.0/24 | プライベート |

#### 3. Internet Gateway作成・アタッチ

- 名前: `portfolio-portfolio-igw`
- アタッチ先VPC: `portfolio-portfolio-vpc`

#### 4. NAT Gateway作成（+ Elastic IP）

- 名前: `portfolio-portfolio-nat-gw`
- 配置サブネット: `public-subnet-1c`（ap-northeast-1c）
- EIP名: `portfolio-portfolio-nat-eip`
- 注意: **作成直後から課金開始**（約$0.062/時間）

#### 5. ルートテーブル設定

**パブリック用（portfolio-portfolio-public-rtb）:**
- ルート: `0.0.0.0/0` → Internet Gateway
- 関連付け: `public-subnet-1a`、`public-subnet-1c`

**プライベート用（portfolio-portfolio-private-rtb）:**
- ルート: `0.0.0.0/0` → NAT Gateway
- 関連付け: `private-subnet-1a`、`private-subnet-1c`

#### 6. セキュリティグループ作成（3つ）

| SG名 | 用途 | インバウンドルール |
|------|------|----------------|
| portfolio-portfolio-sg-alb | ALB用 | HTTP:80 from 0.0.0.0/0 |
| portfolio-portfolio-sg-ec2 | EC2用 | TCP:5000 from SG-ALB、SSH:22 from myIP |
| portfolio-portfolio-sg-rds | RDS用 | MySQL:3306 from SG-EC2 |

### スクリーンショット

`docs/screenshots/` に保存：

- `01-vpc-created.png` - VPC作成後の確認画面
- `02-subnets.png` - サブネット4つの一覧
- `03-nat-gateway.png` - NAT Gateway「Available」状態
- `04-route-tables.png` - ルートテーブル関連付け確認
- `05-security-groups.png` - セキュリティグループ3つの一覧

### 学んだこと・気づき

1. **NAT Gatewayは作成後すぐに課金が始まる** → 学習後は`terraform destroy`で削除を検討
2. **NAT Gatewayが完全に「Available」になるまで約2分かかる** → ルートテーブル設定はステータス確認後に行う
3. **プライベートルートテーブルは1つで1a/1c両サブネットに関連付け可能** → Single-AZ NAT構成の場合は1つで十分
4. **SG-RDSにegressルールを明示しなくてもAWSデフォルトで全アウトバウンド許可が適用される**
5. **VPCリソースマップ（AWSコンソール）で全体のネットワーク構成を一目で確認できる**

### 次回作業予定（次週末）

- [ ] EC2インスタンス起動（public-subnet-1a、t2.micro）
- [ ] RDSインスタンス起動（private subnet、MySQL 8.0、db.t3.micro）
- [ ] ALB作成（public-1a+1c、Listener:80、TG:5000）
- [ ] EC2にSSH接続・Flask+Nginxセットアップ
- [ ] ALB DNS名でTODOアプリの動作確認

---

## 2026/xx/xx（予定）- EC2・RDS・ALB構築

### 作業概要

（次週作業後に記録）

---
