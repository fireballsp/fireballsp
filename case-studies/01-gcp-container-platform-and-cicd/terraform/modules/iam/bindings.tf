resource "google_project_iam_member" "prj_iam_member" {
  for_each = { for i in local.iam_items : i.id => i }
  project  = var.project_id
  role     = each.value.role
  member   = each.value.member
}