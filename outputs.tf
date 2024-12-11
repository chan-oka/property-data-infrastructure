output "bigquery_dataset_id" {
  value = google_bigquery_dataset.property_dataset.dataset_id
}

output "properties_table_id" {
  value = google_bigquery_table.properties.table_id
}

output "error_logs_table_id" {
  value = google_bigquery_table.error_logs.table_id
}