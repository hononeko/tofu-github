# Agent & Contributor Guidelines (`AGENTS.md`)

OpenTofu configuration for every repository in the hononeko org. An apply changes live GitHub settings for all of them, so review the plan before applying.

All automated agents and human contributors must follow the rules in this document.

## 1. Quality Gates

Before committing, all of these must pass:

```bash
tofu fmt -check -recursive
tofu init -backend=false && tofu validate
```

## 2. Rules

* **Standard first:** org-wide defaults live in `modules/repository`. A repository's entry in `repos.tf` only lists what differs from them.
* **Never apply unreviewed:** run `tofu plan` and read every change before `tofu apply`. Agents only apply when explicitly asked.
* **No secrets in the repository:** `backend.tfbackend` and state are git-ignored. State is encrypted client-side.
* **Removing a repository archives it** (`archive_on_destroy`). It is never deleted.
* **Pinned dependencies:** GitHub Actions are pinned by commit SHA with a version comment.

## 3. Commits

[Conventional Commits](https://www.conventionalcommits.org/), enforced locally by the `commit-msg` hook (`git config core.hooksPath .githooks`).
