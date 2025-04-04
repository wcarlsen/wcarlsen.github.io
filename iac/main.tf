locals {
  gh_pages_branch = "gh-pages"
}

resource "github_repository" "this" {
  name        = "wcarlsen.github.io"
  description = "My personal blog"

  visibility             = "public"
  delete_branch_on_merge = true
  auto_init              = true

  dynamic "pages" {
    for_each = true ? [""] : [] # on first run this should false, cannot reference branch that don't exists

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