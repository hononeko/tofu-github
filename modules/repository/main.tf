locals {
  public = var.config.visibility == "public"
  rs     = var.config.ruleset
}

resource "github_repository" "this" {
  name         = var.name
  description  = var.config.description
  homepage_url = var.config.homepage_url
  topics       = var.config.topics
  visibility   = var.config.visibility
  is_template  = var.config.is_template

  has_issues      = var.config.has_issues
  has_projects    = var.config.has_projects
  has_wiki        = var.config.has_wiki
  has_discussions = var.config.has_discussions

  # Squash and rebase only.
  allow_merge_commit          = false
  allow_squash_merge          = true
  allow_rebase_merge          = true
  squash_merge_commit_title   = "COMMIT_OR_PR_TITLE"
  squash_merge_commit_message = "COMMIT_MESSAGES"
  allow_auto_merge            = local.public && var.config.allow_auto_merge # Not available on private repositories on the free plan.
  allow_update_branch         = var.config.allow_update_branch
  delete_branch_on_merge      = true
  web_commit_signoff_required = false

  archive_on_destroy = true

  dynamic "template" {
    for_each = var.config.template == null ? [] : [var.config.template]
    content {
      owner      = "hononeko"
      repository = template.value
    }
  }

  # Secret scanning is only available on public repositories on the free plan.
  dynamic "security_and_analysis" {
    for_each = local.public ? [1] : []
    content {
      secret_scanning {
        status = "enabled"
      }
      secret_scanning_push_protection {
        status = "enabled"
      }
    }
  }

  lifecycle {
    ignore_changes = [template]
  }
}

resource "github_repository_vulnerability_alerts" "this" {
  repository = github_repository.this.name
  enabled    = true
}

resource "github_repository_dependabot_security_updates" "this" {
  repository = github_repository.this.name
  enabled    = var.config.dependabot_security_updates

  depends_on = [github_repository_vulnerability_alerts.this]
}

# Not supported by the provider. Only available on public repositories on the free plan.
resource "terraform_data" "private_vulnerability_reporting" {
  count            = local.public ? 1 : 0
  triggers_replace = github_repository.this.repo_id

  provisioner "local-exec" {
    command = "gh api -X PUT repos/hononeko/${github_repository.this.name}/private-vulnerability-reporting"
  }
}

# Rulesets need a paid plan on private repositories.
resource "github_repository_ruleset" "default" {
  count       = local.public ? 1 : 0
  name        = "Default"
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = local.rs.include
      exclude = []
    }
  }

  bypass_actors {
    actor_type  = "OrganizationAdmin"
    bypass_mode = "always"
  }

  bypass_actors {
    actor_id    = 5 # Repository admin
    actor_type  = "RepositoryRole"
    bypass_mode = "always"
  }

  rules {
    creation                = local.rs.creation
    deletion                = true
    non_fast_forward        = true
    required_linear_history = true
    required_signatures     = local.rs.required_signatures

    pull_request {
      allowed_merge_methods             = ["squash", "rebase"]
      required_approving_review_count   = 0
      dismiss_stale_reviews_on_push     = local.rs.dismiss_stale_reviews_on_push
      required_review_thread_resolution = local.rs.required_review_thread_resolution
      require_code_owner_review         = false
      require_last_push_approval        = false
    }

    dynamic "required_status_checks" {
      for_each = length(local.rs.status_checks) > 0 ? [1] : []
      content {
        strict_required_status_checks_policy = local.rs.strict_status_checks
        do_not_enforce_on_create             = true

        dynamic "required_check" {
          for_each = local.rs.status_checks
          content {
            context        = required_check.value.context
            integration_id = required_check.value.integration_id
          }
        }
      }
    }

    dynamic "required_code_scanning" {
      for_each = length(local.rs.code_scanning) > 0 ? [1] : []
      content {
        dynamic "required_code_scanning_tool" {
          for_each = local.rs.code_scanning
          content {
            tool                      = required_code_scanning_tool.value.tool
            alerts_threshold          = required_code_scanning_tool.value.alerts_threshold
            security_alerts_threshold = required_code_scanning_tool.value.security_alerts_threshold
          }
        }
      }
    }
  }
}
