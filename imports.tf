# Repositories that existed before they were managed here. An import is a no-op once the resource is in state, so
# these can be removed after the apply that imports them.
locals {
  imported_repos = ["traefik-plugin-cloudflare-realip"]
}

import {
  for_each = toset(local.imported_repos)
  to       = module.repo[each.key].github_repository.this
  id       = each.key
}

import {
  for_each = toset(local.imported_repos)
  to       = module.repo[each.key].github_repository_vulnerability_alerts.this
  id       = each.key
}

import {
  for_each = toset(local.imported_repos)
  to       = module.repo[each.key].github_repository_dependabot_security_updates.this
  id       = each.key
}
