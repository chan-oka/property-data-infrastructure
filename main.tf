provider "google" {
  project = var.project_id
  region  = var.region
}

# 必要なAPIの有効化
resource "google_project_service" "required_apis" {
  for_each = toset([
    "bigquery.googleapis.com",
    "cloudscheduler.googleapis.com",
    "pubsub.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com"
  ])

  project                    = var.project_id
  service                    = each.key
  disable_dependent_services = true
  disable_on_destroy         = false
}

# Workload Identity Pool
# resource "google_iam_workload_identity_pool" "property_pool" {
#   project                   = var.project_id
#   workload_identity_pool_id = "property-parser-pool"
#   display_name              = "Property Parser Pool"
#   description               = "Identity pool for property parser application"
# }

# Workload Identity Provider
# resource "google_iam_workload_identity_pool_provider" "property_provider" {
#   workload_identity_pool_id          = google_iam_workload_identity_pool.property_pool.workload_identity_pool_id
#   workload_identity_pool_provider_id = "property-parser-provider"
#   display_name                       = "Property Parser Provider"

#   attribute_mapping = {
#     "google.subject" = "assertion.sub"
#     "attribute.repository" = "assertion.repository"
#     "attribute.repository_owner" = "assertion.repository_owner"
#   }

#   oidc {
#     issuer_uri = "https://token.actions.githubusercontent.com"
#   }

#   attribute_condition = "attribute.repository == assertion.repository && attribute.repository_owner == assertion.repository_owner"
# }

# BigQuery データセット
resource "google_bigquery_dataset" "property_dataset" {
  dataset_id                 = "property_data"
  description                = "Dataset for real estate property information"
  location                   = var.region
  delete_contents_on_destroy = false  
}

# BigQuery テーブル - プロパティ情報
resource "google_bigquery_table" "properties" {
  dataset_id          = google_bigquery_dataset.property_dataset.dataset_id
  table_id            = "properties"
  deletion_protection = false

  time_partitioning {
    type          = "DAY"
    field         = "created_at"
    expiration_ms = 31536000000 # 1年
  }

  clustering = ["prefecture", "city", "property_type", "source_company"]

  schema = jsonencode([
    {
      name        = "id",
      type        = "STRING",
      mode        = "REQUIRED",
      description = "物件ID"
    },
    {
      name        = "email_id",
      type        = "STRING",
      mode        = "REQUIRED",
      description = "メールID"
    },
    {
      name        = "property_name",
      type        = "STRING",
      mode        = "NULLABLE",
      description = "物件名"
    },
    {
      name        = "property_type",
      type        = "STRING",
      mode        = "NULLABLE",
      description = "物件種別（マンション、一戸建て等）"
    },
    {
      name        = "postal_code",
      type        = "STRING",
      mode        = "NULLABLE",
      description = "郵便番号"
    },
    {
      name        = "prefecture",
      type        = "STRING",
      mode        = "NULLABLE",
      description = "都道府県"
    },
    {
      name        = "city",
      type        = "STRING",
      mode        = "NULLABLE",
      description = "市区町村"
    },
    {
      name        = "address",
      type        = "STRING",
      mode        = "NULLABLE",
      description = "番地以降の住所"
    },
    {
      name        = "price",
      type        = "INTEGER",
      mode        = "NULLABLE",
      description = "価格（円）"
    },
    {
      name        = "monthly_fee",
      type        = "INTEGER",
      mode        = "NULLABLE",
      description = "月額費用（円）"
    },
    {
      name        = "management_fee",
      type        = "INTEGER",
      mode        = "NULLABLE",
      description = "管理費（円）"
    },
    {
      name        = "floor_area",
      type        = "FLOAT",
      mode        = "NULLABLE",
      description = "専有面積（㎡）"
    },
    {
      name        = "floor_number",
      type        = "INTEGER",
      mode        = "NULLABLE",
      description = "階数"
    },
    {
      name        = "total_floors",
      type        = "INTEGER",
      mode        = "NULLABLE",
      description = "建物の総階数"
    },
    {
      name        = "nearest_station",
      type        = "STRING",
      mode        = "NULLABLE",
      description = "最寄駅"
    },
    {
      name        = "station_distance",
      type        = "INTEGER",
      mode        = "NULLABLE",
      description = "駅までの距離（分）"
    },
    {
      name        = "building_age",
      type        = "INTEGER",
      mode        = "NULLABLE",
      description = "築年数"
    },
    {
      name        = "construction_date",
      type        = "DATE",
      mode        = "NULLABLE",
      description = "建築年月日"
    },
    {
      name        = "features",
      type        = "STRING",
      mode        = "REPEATED",
      description = "設備・特徴"
    },
    {
      name        = "status",
      type        = "STRING",
      mode        = "REQUIRED",
      description = "状態（募集中、成約済み等）"
    },
    {
      name        = "source_company",
      type        = "STRING",
      mode        = "REQUIRED",
      description = "情報提供会社"
    },
    {
      name        = "company_phone",
      type        = "STRING",
      mode        = "NULLABLE",
      description = "情報提供会社の電話番号"
    },
    {
      name        = "company_email",
      type        = "STRING",
      mode        = "NULLABLE",
      description = "情報提供会社のメールアドレス"
    },
    {
      name        = "property_url",
      type        = "STRING",
      mode        = "NULLABLE",
      description = "物件の詳細ページURL"
    },
    {
      name        = "road_price",
      type        = "INTEGER",
      mode        = "NULLABLE",
      description = "路線価（円/㎡）"
    },
    {
      name        = "estimated_price",
      type        = "INTEGER",
      mode        = "NULLABLE",
      description = "積算価格（円）"
    },
    {
      name        = "current_rent_income",
      type        = "INTEGER",
      mode        = "NULLABLE",
      description = "現況の家賃収入（円/月）"
    },
    {
      name        = "expected_rent_income",
      type        = "INTEGER",
      mode        = "NULLABLE",
      description = "想定の家賃収入（円/月）"
    },
    {
      name        = "yield_rate",
      type        = "FLOAT",
      mode        = "NULLABLE",
      description = "利回り（%）"
    },
    {
      name        = "land_area",
      type        = "FLOAT",
      mode        = "NULLABLE",
      description = "敷地面積（㎡）"
    },
    {
      name        = "email_subject",
      type        = "STRING",
      mode        = "REQUIRED",
      description = "メールタイトル"
    },
    {
      name        = "email_body",
      type        = "STRING",
      mode        = "REQUIRED",
      description = "メール本文"
    },
    {
      name        = "email_received_at",
      type        = "TIMESTAMP",
      mode        = "REQUIRED",
      description = "メール受信日時"
    },
    {
      name        = "email_from",
      type        = "STRING",
      mode        = "REQUIRED",
      description = "メール送信元アドレス"
    },
    {
      name        = "created_at",
      type        = "TIMESTAMP",
      mode        = "REQUIRED",
      description = "レコード作成日時"
    },
    {
      name        = "updated_at",
      type        = "TIMESTAMP",
      mode        = "REQUIRED",
      description = "レコード更新日時"
    }
  ])
}

# BigQuery テーブル - エラーログ
resource "google_bigquery_table" "error_logs" {
  dataset_id          = google_bigquery_dataset.property_dataset.dataset_id
  table_id            = "error_logs"
  deletion_protection = false

  time_partitioning {
    type  = "DAY"
    field = "created_at"
  }

  schema = jsonencode([
    {
      name        = "error_id",
      type        = "STRING",
      mode        = "REQUIRED",
      description = "エラーID"
    },
    {
      name        = "email_id",
      type        = "STRING",
      mode        = "REQUIRED",
      description = "処理対象のメールID"
    },
    {
      name        = "error_type",
      type        = "STRING",
      mode        = "REQUIRED",
      description = "エラーの種類"
    },
    {
      name        = "error_message",
      type        = "STRING",
      mode        = "REQUIRED",
      description = "エラーメッセージ"
    },
    {
      name        = "email_content",
      type        = "STRING",
      mode        = "NULLABLE",
      description = "メール本文"
    },
    {
      name        = "stack_trace",
      type        = "STRING",
      mode        = "NULLABLE",
      description = "スタックトレース"
    },
    {
      name        = "created_at",
      type        = "TIMESTAMP",
      mode        = "REQUIRED",
      description = "エラー発生日時"
    }
  ])
}

# Cloud Storage バケット（Cloud Functions用）
resource "google_storage_bucket" "function_source" {
  name     = "${var.project_id}-function-source"
  location = var.region
  uniform_bucket_level_access = true
}

# Cloud Functions用のサービスアカウント
resource "google_service_account" "function_identity" {
  account_id   = "property-parser-identity"
  display_name = "Property Parser Function Identity"
}

resource "google_project_iam_member" "function_roles" {
  for_each = toset([
    "roles/bigquery.dataEditor",
    "roles/aiplatform.user"
  ])

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.function_identity.email}"
}