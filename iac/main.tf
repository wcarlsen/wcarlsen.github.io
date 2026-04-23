locals {
  gh_pages_branch = "gh-pages"
  name            = "wcarlsen.github.io"
}

resource "github_repository" "this" {
  name         = local.name
  description  = "My personal blog"
  homepage_url = local.name

  visibility             = "public"
  delete_branch_on_merge = true
  auto_init              = true
  has_issues             = true

  dynamic "pages" {
    for_each = true ? [""] : [] # on first run this should be false, cannot reference branch that don't exists

    content {
      source {
        branch = local.gh_pages_branch
      }
    }
  }
}

resource "github_branch_default" "this" {
  repository = github_repository.this.name
  branch     = "main"
}

resource "github_branch" "this" {
  repository = github_repository.this.name
  branch     = local.gh_pages_branch
  depends_on = [github_branch_default.this]
}

resource "github_workflow_repository_permissions" "this" {
  default_workflow_permissions     = "write"
  can_approve_pull_request_reviews = false
  repository                       = github_repository.this.name
}

resource "github_actions_secret" "renovate" {
  repository      = github_repository.this.name
  secret_name     = "RENOVATE_TOKEN" # pragma: allowlist secret
  plaintext_value = var.github_token
}
