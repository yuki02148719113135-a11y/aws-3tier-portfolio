# VPC設計書 - AWS 3層Webアプリケーション ポートフォリオ

**作成日**: 2026年2月22日
**プロジェクト**: AWS 3層Webアプリケーション ポートフォリオ
**バージョン**: 1.0

---

## 1. 設計概要

### 1.1 目的

- AWS SAA/SAP資格の知識を実務レベルで可視化するポートフォリオ
- 3層Webアプリケーション（ALB → EC2 → RDS）のインフラをTerraformでコード化
- 転職活動において「設計→IaC化→構築→動作確認」の一連スキルをアピール

### 1.2 設計方針

| 方針 | 内容 |
|------|------|
| セキュリティ | 最小権限の原則。RDSはプライベートサブネットに隔離、SGは用途別に分離 |
| 可用性 | 2つのAZ（1a/1c）にリソースを分散配置（Multi-AZ構成） |
| コスト | 無料枠を最大活用。NAT Gatewayは1台に集約（Single-AZ NAT構成） |
| IaC | Terraform v1.7+ で全リソースをコード化・再現可能 |

---

## 2. ネットワーク設計

### 2.1 VPC基本情報

| 項目 | 値 |
|------|----|
| VPC名 | portfolio-portfolio-vpc |
| CIDRブロック | 10.0.0.0/16 |
| リージョン | ap-northeast-1（東京） |
| DNSホスト名 | 有効（`enable_dns_hostnames = true`） |
| DNSサポート | 有効（`enable_dns_support = true`） |
| 利用可能IP数 | 65,536（/16） |

### 2.2 サブネット設計

| サブネット名 | AZ | CIDR | 用途 | パブリックIP自動割り当て |
|------------|-----|------|------|----------------------|
| portfolio-portfolio-public-subnet-1a | ap-northeast-1a | 10.0.1.0/24 | ALB、EC2 | 有効 |
| portfolio-portfolio-public-subnet-1c | ap-northeast-1c | 10.0.2.0/24 | ALB、NAT Gateway | 有効 |
| portfolio-portfolio-private-subnet-1a | ap-northeast-1a | 10.0.11.0/24 | RDS（Primary候補） | 無効 |
| portfolio-portfolio-private-subnet-1c | ap-northeast-1c | 10.0.12.0/24 | RDS（Standby候補） | 無効 |

各 /24 サブネットの有効ホスト数: **251個**（AWSが先頭4つ+末尾1つを予約）

### 2.3 IP割り当て計画

| 用途 | サブネット | 割り当て方式 |
|------|---------|------------|
| EC2 Webサーバー | public-1a | 動的（map_public_ip_on_launch） |
| NAT Gateway EIP | public-1c | 静的（Elastic IP） |
| RDS | private-1a / 1c | DBサブネットグループ経由で動的割り当て |

---

## 3. ルーティング設計

### 3.1 パブリック用ルートテーブル（portfolio-portfolio-public-rtb）

| 送信先 | ターゲット | 説明 |
|--------|---------|------|
| 10.0.0.0/16 | local | VPC内通信（暗黙のルール） |
| 0.0.0.0/0 | Internet Gateway | インターネット向け通信 |

**関連付け**: public-subnet-1a、public-subnet-1c

### 3.2 プライベート用ルートテーブル（portfolio-portfolio-private-rtb）

| 送信先 | ターゲット | 説明 |
|--------|---------|------|
| 10.0.0.0/16 | local | VPC内通信（暗黙のルール） |
| 0.0.0.0/0 | NAT Gateway（public-1c配置） | インターネット向けをNAT経由に |

**関連付け**: private-subnet-1a、private-subnet-1c（2つのAZで共有）

> **設計トレードオフ**: プライベートルートテーブルは1つのみ作成し、1a/1c両サブネットに関連付け（Single-AZ NAT構成）。NAT Gatewayが配置されたap-northeast-1cが障害になると、ap-northeast-1aのアウトバウンドも停止するリスクを、コスト削減を優先して許容している。

---

## 4. セキュリティ設計

### 4.1 SG-ALB（portfolio-portfolio-sg-alb）

**用途**: Application Load Balancer用

#### インバウンドルール

| プロトコル | ポート | 送信元 | 説明 |
|---------|------|--------|------|
| TCP | 80（HTTP） | 0.0.0.0/0 | インターネットからのHTTPアクセス |

> **注意**: HTTPS（443）は現時点では未実装。ACM証明書取得後にリスナー追加予定。

#### アウトバウンドルール

| プロトコル | ポート | 送信先 |
|---------|------|--------|
| All（-1） | All | 0.0.0.0/0 |

---

### 4.2 SG-EC2（portfolio-portfolio-sg-ec2）

**用途**: EC2 Webサーバー用

#### インバウンドルール

| プロトコル | ポート | 送信元 | 説明 |
|---------|------|--------|------|
| TCP | 5000（Flask） | SG-ALB（security_group参照） | ALBからのアプリトラフィックのみ |
| TCP | 22（SSH） | var.myip（/32） | 管理者のSSH接続のみ許可 |

#### アウトバウンドルール

| プロトコル | ポート | 送信先 |
|---------|------|--------|
| All（-1） | All | 0.0.0.0/0 |

---

### 4.3 SG-RDS（portfolio-portfolio-sg-rds）

**用途**: RDS MySQL用

#### インバウンドルール

| プロトコル | ポート | 送信元 | 説明 |
|---------|------|--------|------|
| TCP | 3306（MySQL） | SG-EC2（security_group参照） | EC2からのDB接続のみ |

#### アウトバウンドルール

なし（Terraformにegress未定義 = AWSデフォルトで全アウトバウンド許可が適用）

---

## 5. ゲートウェイ設計

### 5.1 Internet Gateway（IGW）

| 項目 | 値 |
|------|----|
| 名前 | portfolio-portfolio-igw |
| アタッチ先VPC | portfolio-portfolio-vpc |
| 用途 | パブリックサブネットとインターネット間の通信 |

### 5.2 NAT Gateway

| 項目 | 値 |
|------|----|
| 名前 | portfolio-portfolio-nat-gw |
| 配置サブネット | public-subnet-1c（ap-northeast-1c） |
| 関連EIP名 | portfolio-portfolio-nat-eip |
| 用途 | プライベートサブネットからのアウトバウンド通信 |
| 依存関係 | `depends_on = [aws_internet_gateway.main]`（IGW作成後に作成） |
| 推定コスト | 約$33/月（稼働し続ける場合） |

---

## 6. コンポーネント配置設計

### 6.1 Application Load Balancer（ALB）

| 項目 | 値 |
|------|----|
| 名前 | portfolio-portfolio-alb |
| タイプ | application（L7） |
| インターネット向け | true（internal = false） |
| 配置サブネット | public-1a、public-1c（Multi-AZ必須） |
| セキュリティグループ | SG-ALB |
| リスナー | HTTP:80 → ターゲットグループ（forward） |
| ターゲットグループ | portfolio-portfolio-tg（port:5000、protocol:HTTP） |
| ヘルスチェック | GET /、200応答、interval:30s、threshold:2回 |

### 6.2 EC2（Webサーバー）

| 項目 | 値 |
|------|----|
| 名前 | portfolio-portfolio-ec2-web |
| AMI | ami-094dc5cf74289dfbc（Amazon Linux 2023） |
| インスタンスタイプ | t2.micro（無料枠） |
| 配置サブネット | public-subnet-1a |
| セキュリティグループ | SG-EC2 |
| アプリポート | 5000（Flask） |
| リバースプロキシ | Nginx（port:80 → 127.0.0.1:5000） |
| ストレージ | 8GB gp3 |

### 6.3 RDS（データベース）

| 項目 | 値 |
|------|----|
| 識別子 | portfolio-portfolio-rds |
| エンジン | MySQL 8.0 |
| インスタンスクラス | db.t3.micro（無料枠） |
| ストレージ | 20GB gp2 |
| DB名 | todo_db |
| ユーザー名 | admin（var.db_username） |
| マルチAZ | false（コスト削減のためSingle-AZ） |
| パブリックアクセス | false（プライベートサブネットのみ） |
| バックアップ保持期間 | 7日間 |
| サブネットグループ | private-1a + private-1c |

---

## 7. 構築順序

### Phase 1: ネットワーク基盤（2026/02/22 完了）

- [x] VPC作成（10.0.0.0/16）
- [x] パブリックサブネット作成（1a: 10.0.1.0/24、1c: 10.0.2.0/24）
- [x] プライベートサブネット作成（1a: 10.0.11.0/24、1c: 10.0.12.0/24）
- [x] Internet Gateway作成・アタッチ
- [x] NAT Gateway作成（public-1cに配置）+ EIP取得
- [x] ルートテーブル作成（パブリック/プライベート）+ サブネット関連付け

### Phase 2: セキュリティ設定（2026/02/22 完了）

- [x] SG-ALB作成（HTTP:80 from 0.0.0.0/0）
- [x] SG-EC2作成（TCP:5000 from SG-ALB、SSH:22 from myIP）
- [x] SG-RDS作成（MySQL:3306 from SG-EC2）

### Phase 3: コンピュート・データベース（次週末予定）

- [ ] EC2インスタンス作成（public-subnet-1a、Nginx+Flask自動セットアップ）
- [ ] RDSインスタンス作成（private subnet、Single-AZ）
- [ ] ALB作成 + ターゲットグループ + HTTPリスナー設定

### Phase 4: アプリ動作確認（Phase 3完了後）

- [ ] EC2へSSH接続してFlaskアプリデプロイ
- [ ] ALB DNS名でTODOアプリへのHTTPアクセス確認
- [ ] TODO CRUD操作（追加・完了・削除）の動作確認

---

## 8. 監視・運用設計（将来実装）

| 項目 | 対象 | 実装フェーズ |
|------|------|-----------|
| CloudWatch Alarms | EC2 CPU > 80%、RDS FreeStorageSpace | Phase 5 |
| ALBアクセスログ | S3バケットへの保存 | Phase 5 |
| VPC Flow Logs | 異常通信の検知 | Phase 5 |
| CloudWatch Dashboard | 統合監視ダッシュボード | Phase 5 |

---

## 9. コスト見積もり（月間）

| サービス | スペック | 月額（USD） | 無料枠 |
|--------|--------|----------|------|
| EC2 | t2.micro | $0 | 750時間/月（12ヶ月） |
| RDS | db.t3.micro、Single-AZ、20GB | $0 | 750時間/月（12ヶ月） |
| ALB | - | 〜$16 | なし |
| NAT Gateway | 1台、$0.062/時間 | 〜$45 | なし |
| EIP（NAT用） | 接続中は無料 | $0 | 接続中は無料 |
| **合計** | | **〜$61** | |

> **コスト削減策**: `terraform destroy` で未使用時は全リソース削除を推奨。NAT Gatewayは作成直後から課金開始。

---

## 10. セキュリティチェックリスト

### 実装済み

- [x] RDSをプライベートサブネットに配置（`publicly_accessible = false`）
- [x] セキュリティグループで最小権限の原則を適用
- [x] SSH接続を特定IPからのみ許可（`var.myip/32`）
- [x] DBパスワードをtfvarsで管理（`.gitignore`で除外）
- [x] DB接続情報を`sensitive`フラグで保護（`outputs.tf`）

### 未実装（今後の課題）

- [ ] HTTPS化（ACM証明書 + ALBリスナー443追加）
- [ ] VPC Flow Logsの有効化
- [ ] Secrets ManagerでのDB認証情報管理
- [ ] RDSストレージ暗号化（`storage_encrypted = true`）
- [ ] CloudTrail有効化

---

## 11. 今後の拡張計画

| フェーズ | 内容 | 優先度 |
|--------|------|------|
| Phase 5 | HTTPS化（ACM + ALBリスナー443追加） | 高 |
| Phase 5 | CloudWatch監視設定 | 高 |
| Phase 6 | Auto Scaling（EC2 ASG） | 中 |
| Phase 6 | RDS Multi-AZ化（本番環境想定） | 中 |
| Phase 7 | CloudFront + S3静的コンテンツ配信 | 低 |
| Phase 7 | Route 53独自ドメイン設定 | 低 |
| Phase 8 | GitHub Actions CI/CDパイプライン | 低 |
| Phase 9 | ECS/Fargateへのコンテナ移行 | 低 |

---

## 参考資料

- Terraform実装: [terraform/vpc.tf](../terraform/vpc.tf)
- セキュリティグループ実装: [terraform/security_groups.tf](../terraform/security_groups.tf)
- AWS VPC公式ドキュメント: https://docs.aws.amazon.com/vpc/latest/userguide/
- AWS Well-Architected Framework: https://aws.amazon.com/architecture/well-architected/
