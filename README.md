# lesson-7 — EKS + ECR + Helm (Django)

Terraform створює в AWS (регіон `eu-north-1`) мережу, ECR і кластер Kubernetes (EKS); Django-застосунок розгортається в кластері Helm-чартом.

## Структура

~~~
.
├── main.tf                  # Провайдер AWS і підключення модулів
├── backend.tf               # Бекенд стейту (S3 + DynamoDB)
├── outputs.tf               # Загальні outputs
├── modules/
│   ├── s3-backend/          # S3-бакет для стейту + DynamoDB для блокування
│   ├── vpc/                 # VPC, 3 публічні + 3 приватні підмережі, IGW, NAT, маршрути
│   ├── ecr/                 # ECR-репозиторій lesson-7-django (scan on push)
│   └── eks/                 # IAM-ролі, EKS-кластер, node group (2 x t3.small), metrics-server
├── charts/django-app/
│   ├── Chart.yaml
│   ├── values.yaml          # Образ, сервіс, ресурси, autoscaler, змінні ConfigMap
│   └── templates/
│       ├── deployment.yaml  # Образ з ECR, envFrom -> ConfigMap
│       ├── service.yaml     # type: LoadBalancer, 80 -> 8000
│       ├── configmap.yaml   # Змінні середовища з values.config
│       └── hpa.yaml         # 2-6 подів, CPU > 70%
└── app/                     # Django-проєкт з теми 4 + Dockerfile
~~~

## Модулі

- **s3-backend** — бакет зі стейтом (версіювання, шифрування, без публічного доступу) і таблиця `terraform-locks` для блокування.
- **vpc** — мережа `10.0.0.0/16`. Публічні підмережі мають тег `kubernetes.io/role/elb=1`, тому Service типу LoadBalancer створює балансувальник саме в них.
- **ecr** — репозиторій для Docker-образу Django.
- **eks** — кластер `lesson-7-eks` у приватних підмережах, 2 ноди `t3.small`, add-on `metrics-server` (метрики для HPA). Ноди мають доступ на читання з ECR.

## ConfigMap

Змінні з теми 4 (`DJANGO_*`, `POSTGRES_*`) задані у `values.yaml -> config`. Helm створює з них ConfigMap `django-config`, а Deployment підключає його через `envFrom.configMapRef`. `app/config/settings.py` читає ці змінні з оточення.

У кластері немає PostgreSQL, тому `DB_ENGINE: "sqlite"` — Django використовує SQLite. Для зовнішньої БД достатньо встановити `DB_ENGINE: "postgres"` і `POSTGRES_HOST`.

## Запуск

### 1. Інфраструктура

~~~bash
mv backend.tf backend.tf.off          # перший запуск — локальний стейт
terraform init
terraform plan
terraform apply
mv backend.tf.off backend.tf
terraform init -migrate-state         # стейт -> S3
~~~

### 2. Доступ до кластера

~~~bash
aws eks update-kubeconfig --region eu-north-1 --name lesson-7-eks
kubectl get nodes
~~~

### 3. Образ Django -> ECR

~~~bash
ECR=$(terraform output -raw ecr_repository_url)
aws ecr get-login-password --region eu-north-1 | docker login --username AWS --password-stdin ${ECR%%/*}
docker build -t $ECR:latest ./app
docker push $ECR:latest
~~~

### 4. Helm

~~~bash
helm lint charts/django-app
helm install django charts/django-app
kubectl get pods,svc,hpa,configmap
kubectl exec deploy/django -- env | grep -E "DJANGO|DB_ENGINE|POSTGRES"
~~~

Застосунок доступний за адресою з колонки `EXTERNAL-IP` сервісу `django`.

### 5. Перевірка HPA

~~~bash
for i in 1 2 3; do kubectl run load-$i --image=busybox --restart=Never -- sh -c "while true; do wget -q -O- http://django/ >/dev/null; done"; done
kubectl get hpa django -w
kubectl delete pod load-1 load-2 load-3
~~~

Під навантаженням HPA збільшив кількість подів з 2 до 6.

## Видалення

Спершу Helm-реліз, інакше балансувальник залишиться у VPC і `destroy` не видалить підмережі:

~~~bash
helm uninstall django
mv backend.tf backend.tf.off
terraform init -migrate-state         # стейт S3 -> локально
terraform destroy
mv backend.tf.off backend.tf
~~~
