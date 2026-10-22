output "html_url" {
  value = github_repository.this.html_url
}

output "ruleset_id" {
  value = one(github_repository_ruleset.default[*].ruleset_id)
}
