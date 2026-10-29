# Repositories that existed before they were managed here. An import is a no-op once the resource is in state, so
# these can be removed after the apply that imports them.
locals {
  imported_repos = ["traefik-plugin-cloudflare-realip", "sshx", "doppel"]

  # Default rulesets that existed before their repository was managed here, by repository.
  imported_rulesets = {
    sshx   = 24340693
    doppel = 24518954
  }
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

import {
  for_each = local.imported_rulesets
  to       = module.repo[each.key].github_repository_ruleset.default[0]
  id       = "${each.key}:${each.value}"
}
