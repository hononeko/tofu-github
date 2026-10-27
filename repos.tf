# Every repository in the hononeko org. Settings left out use the standard in modules/repository.
# Removing a repository from this map archives it.
locals {
  github_actions = 15368
  gitguardian    = 46505

  codeql = [{ tool = "CodeQL" }]

  # validate / Lint & Test, both image builds and GitGuardian.
  image_checks = [
    { context = "validate / Lint & Test", integration_id = local.github_actions },
    { context = "image / Image (amd64)", integration_id = local.github_actions },
    { context = "image / Image (arm64)", integration_id = local.github_actions },
    { context = "GitGuardian Security Checks", integration_id = local.gitguardian },
  ]

  repos = {
    ".github" = {}

    actions = {
      description = "Shared GitHub Actions: Conventional Commit versioning and grouped release notes"
      ruleset = {
        status_checks = [for c in [
          "validate / Lint & Test",
          "validate / Run the actions",
          "validate / Smoke test action",
          "validate / Version rules (feat)",
          "validate / Version rules (fix)",
          "validate / Version rules (docs and test only)",
          "validate / Version rules (bang)",
          "validate / Version rules (footer)",
          "validate / Version rules (mentioned, not a footer)",
          "validate / Version rules (feat mentioned in a fix)",
        ] : { context = c }]
      }
    }

    bw-cli-docker = {
      description = "Simple Docker Image wrapper that runs the Bitwarden CLI and exposes it as a simple REST API webhook"
      ruleset = {
        status_checks = [
          { context = "test-and-build", integration_id = local.github_actions },
          { context = "GitGuardian Security Checks", integration_id = local.gitguardian },
        ]
      }
    }

    cs-edl-bouncer = {
      description = "Lightweight, zero-dependency CrowdSec External Dynamic List (EDL) bouncer with CIDR aggregation and deterministic sharding"
      ruleset = {
        status_checks        = local.image_checks
        strict_status_checks = true
        code_scanning        = local.codeql
      }
    }

    electric-pickle = {
      visibility = "private"
    }

    homelab-launchpad = {
      description = "Modular homelab startpage and launchpad with auto-discovery for HTTP Routes, ArgoCD GitOps sync status, and real-time cluster telemetry."
      ruleset = {
        dismiss_stale_reviews_on_push     = true
        required_review_thread_resolution = true
        status_checks = [for c in [
          "validate / Lint, Test & Build",
          "image / Image (amd64)",
          "image / Image (arm64)",
          "CodeQL",
          "GitGuardian Security Checks",
        ] : { context = c }]
      }
    }

    homelab-utils-docker = {
      description = "Lean, purpose-built Docker utility images for homelab workloads"
    }

    koshin = {
      description = "Stateless, horizontally scalable Renovate CLI orchestrator (Kotlin/Ktor, NATS JetStream, Valkey, KEDA)"
    }

    media-webhook-notifier = {
      description = "Lightweight native Kotlin media webhook notifier with live Telegram progress cards"
      ruleset = {
        dismiss_stale_reviews_on_push = true
        status_checks = [
          { context = "validate / Lint & Test", integration_id = local.github_actions },
          { context = "validate / Integration Tests", integration_id = local.github_actions },
          { context = "GitGuardian Security Checks", integration_id = local.gitguardian },
        ]
      }
    }

    minecraft-operator = {
      visibility = "private"
    }

    qbit-gluetun-sync = {
      description = "Lightweight, event-driven Go sidecar that synchronizes dynamic port forwarding from Gluetun (ProtonVPN/WireGuard) to qBittorrent via WebUI."
      ruleset = {
        status_checks = local.image_checks
        code_scanning = local.codeql
      }
    }

    qbit-ntfy-sidecar = {
      description = "A lightweight Go-based sidecar that monitors qBittorrent downloads and sends real-time progress updates and completion alerts to ntfy"
      ruleset = {
        status_checks        = local.image_checks
        strict_status_checks = true
      }
    }

    repo-template = {
      is_template = true
    }

    thread-udp-proxy = {
      description = "Tiny UDP NAT relay that pins Matter traffic to a Thread mesh through one OpenThread Border Router"
      topics      = ["homelab", "kubernetes", "matter", "openthread", "otbr", "thread"]
      ruleset = {
        status_checks = local.image_checks
        code_scanning = local.codeql
      }
    }

    threadificatorr = {
      dependabot_security_updates = true
      ruleset = {
        include       = ["~DEFAULT_BRANCH", "refs/heads/release/**"]
        creation      = true
        code_scanning = local.codeql
      }
    }

    tofu-github = {
      description = "OpenTofu configuration for the hononeko GitHub org"
      topics      = ["opentofu", "github"]
      ruleset = {
        status_checks = [{ context = "Validate", integration_id = local.github_actions }]
      }
    }
  }
}

module "repo" {
  source   = "./modules/repository"
  for_each = local.repos

  name   = each.key
  config = each.value
}

output "repos" {
  value = { for name, repo in module.repo : name => repo.html_url }
}
