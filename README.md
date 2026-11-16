# lesson-5 — Terraform: S3 backend, VPC, ECR (AWS)

Terraform-проєкт, що розгортає в AWS (регіон `eu-north-1`):
- **S3 + DynamoDB** — віддалене зберігання стейту з версіюванням і блокуванням;
- **VPC** — 3 публічні та 3 приватні підмережі, Internet Gateway, NAT Gateway, Route Tables;
- **ECR** — репозиторій Docker-образів зі скануванням при push.

## Структура проєкту

```
lesson-5/
├── main.tf                  # Провайдер AWS і підключення модулів
├── backend.tf               # Бекенд для стейту (S3 + DynamoDB)
├── outputs.tf               # Загальні outputs з усіх модулів
├── modules/
│   ├── s3-backend/
│   │   ├── s3.tf            # S3-бакет: версіювання, шифрування, блок публічного доступу
│   │   ├── dynamodb.tf      # DynamoDB-таблиця для state locking
│   │   ├── variables.tf
│   │   └── outputs.tf       # URL бакета, назва таблиці
│   ├── vpc/
│   │   ├── vpc.tf           # VPC, підмережі, Internet Gateway, EIP, NAT Gateway
│   │   ├── routes.tf        # Route Tables і асоціації з підмережами
│   │   ├── variables.tf
│   │   └── outputs.tf       # ID VPC, підмереж, шлюзів
│   └── ecr/
│       ├── ecr.tf           # ECR-репозиторій, політика доступу, lifecycle policy
│       ├── variables.tf
│       └── outputs.tf       # URL репозиторію
└── README.md
```

## Модулі

### s3-backend
- `aws_s3_bucket` — бакет для `terraform.tfstate`.
- `aws_s3_bucket_versioning` — версіювання: історія змін стейту і можливість відкату.
- `aws_s3_bucket_server_side_encryption_configuration` — шифрування AES256.
- `aws_s3_bucket_public_access_block` — заборона публічного доступу.
- `aws_dynamodb_table` — таблиця `terraform-locks` (ключ `LockID`): блокує стейт під час `apply`, щоб два запуски не змінили його одночасно.

Outputs: `s3_bucket_url`, `s3_bucket_name`, `dynamodb_table_name`.

### vpc
- `aws_vpc` — мережа `10.0.0.0/16`.
- 3 публічні підмережі (`10.0.1-3.0/24`) і 3 приватні (`10.0.4-6.0/24`) у зонах `eu-north-1a/b/c`.
- `aws_internet_gateway` — вихід в інтернет для публічних підмереж.
- `aws_eip` + `aws_nat_gateway` — вихідний доступ в інтернет для приватних підмереж.
- Публічна Route Table: `0.0.0.0/0 → Internet Gateway`; приватна: `0.0.0.0/0 → NAT Gateway`.

Outputs: `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `internet_gateway_id`, `nat_gateway_id`.

### ecr
- `aws_ecr_repository` — репозиторій `lesson-5-ecr`, `scan_on_push = true`.
- `aws_ecr_repository_policy` — push/pull дозволено лише поточному AWS-акаунту.
- `aws_ecr_lifecycle_policy` — зберігає 10 останніх образів.

Output: `repository_url`.

## Запуск

S3-бакет для стейту створює сам проєкт, тому перший запуск — у два етапи.

**1. Створення ресурсів з локальним стейтом** (блок `backend "s3"` тимчасово вимкнено — файл `backend.tf` перейменовано на `backend.tf.off`):
```bash
terraform init
terraform plan
terraform apply
```

**2. Перенесення стейту в S3:**
```bash
mv backend.tf.off backend.tf
terraform init -migrate-state
terraform output
```

## Видалення ресурсів

Спершу повернути стейт локально, бо `destroy` видаляє і бакет зі стейтом:
```bash
mv backend.tf backend.tf.off
terraform init -migrate-state
terraform destroy
mv backend.tf.off backend.tf
```

> NAT Gateway та Elastic IP оплачуються погодинно — після перевірки обов'язково виконуйте `terraform destroy`.

## Команди

| Команда | Дія |
|---|---|
| `terraform init` | Завантажує провайдери, ініціалізує модулі та бекенд |
| `terraform plan` | Показує, що буде створено / змінено / видалено |
| `terraform apply` | Створює або оновлює ресурси в AWS |
| `terraform destroy` | Видаляє всі ресурси проєкту |
| `terraform output` | Виводить URL бакета, назву таблиці, ID VPC, URL ECR |
