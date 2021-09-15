locals {
  apis = [
    "cloudresourcemanager.googleapis.com"
  ]
  regular_roles = [
    "roles/iam.serviceAccountCreator",
    "roles/iam.serviceAccountDeleter"
  ]
  grantable_roles = [
    "roles/logging.admin",
    "roles/monitoring.admin",
    "roles/cloudkms.cryptoKeyEncrypterDecrypter",
    "roles/iam.roleViewer"
  ]
  sa_name = "limited-sa"
}

resource "google_service_account" "myaccount" {
  project      = var.project_id
  account_id   = local.sa_name
  display_name = "Limited Service Account"
}

resource "google_service_account_key" "mykey" {
  service_account_id = google_service_account.myaccount.name
}

resource "local_file" "sa-creds" {
  content  = base64decode(google_service_account_key.mykey.private_key)
  filename = "${local.sa_name}.json"
}

resource "google_project_service" "gcp_services" {
  for_each = toset(local.apis)
  project  = var.project_id
  service  = each.key
}

resource "google_project_iam_member" "grantable_roles" {
  project = var.project_id

  role = "roles/iam.securityAdmin"

  member = "serviceAccount:${google_service_account.myaccount.email}"
  condition {
    title       = "Limit grantable roles"
    description = "Limit grantable roles"
    expression  = "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly(${jsonencode(local.grantable_roles)})"

  }

}

resource "google_project_iam_member" "iam-policy-limited" {
  for_each = toset(local.regular_roles)
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.myaccount.email}"
}
