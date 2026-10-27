variable "name" {
  type        = string
  description = "Repository name"
}

variable "config" {
  description = "Repository settings. Anything left out uses the org standard."
  type = object({
    description  = optional(string)
    homepage_url = optional(string)
    topics       = optional(set(string), [])
    visibility   = optional(string, "public")
    is_template  = optional(bool, false)
    # Template used when the repository is created. Ignored afterwards; null creates an empty repository.
    template = optional(string, "repo-template")

    has_issues          = optional(bool, true)
    has_projects        = optional(bool, true)
    has_wiki            = optional(bool, false)
    has_discussions     = optional(bool, false)
    allow_auto_merge    = optional(bool, true)
    allow_update_branch = optional(bool, false)

    dependabot_security_updates = optional(bool, false)

    # CodeQL's default setup: null leaves it as it is. false for a repository that runs CodeQL from a workflow, since
    # GitHub rejects a workflow's results while the default setup is on.
    codeql_default_setup = optional(bool)

    # "Default" ruleset on the default branch. Only applied to public repositories (free plan).
    ruleset = optional(object({
      include                           = optional(list(string), ["~DEFAULT_BRANCH"])
      creation                          = optional(bool, false)
      required_signatures               = optional(bool, true)
      dismiss_stale_reviews_on_push     = optional(bool, false)
      required_review_thread_resolution = optional(bool, false)
      strict_status_checks              = optional(bool, false)
      status_checks = optional(list(object({
        context        = string
        integration_id = optional(number)
      })), [])
      code_scanning = optional(list(object({
        tool                      = string
        alerts_threshold          = optional(string, "errors")
        security_alerts_threshold = optional(string, "high_or_higher")
      })), [])
    }), {})
  })
  default = {}

  validation {
    condition     = contains(["public", "private"], var.config.visibility)
    error_message = "visibility must be public or private."
  }
}
