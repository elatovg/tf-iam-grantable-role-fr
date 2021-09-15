locals {
  roles = [
    "roles/cloudkms.cryptoKeyEncrypterDecrypter",
    "roles/logging.logWriter"
  ]
}

resource "google_service_account" "my_service_account" {
  project      = var.project_id
  account_id   = "test-sa"
  display_name = "My Service Account"
}

resource "google_project_iam_member" "iam-policy-test-sa" {
  for_each = toset(local.roles)
  project  = var.project_id
  role     = each.key
  member   = "serviceAccount:${google_service_account.my_service_account.email}"
}
