# tofu-github

OpenTofu configuration for every repository in the [hononeko](https://github.com/hononeko) org: settings, the "Default" ruleset, secret scanning and vulnerability reporting.

## Standard

Every repository gets these unless `repos.tf` overrides them:

* **Merging:** squash and rebase only, auto-merge on (public repositories only), branches deleted after merge.
* **Features:** issues and projects on; wiki and discussions off.
* **Security:** Dependabot alerts on. Public repositories also get secret scanning with push protection and private vulnerability reporting. CodeQL's default setup is left as it is, unless `codeql_default_setup` is set: `false` for a repository that runs CodeQL from a workflow, since GitHub rejects a workflow's results while the default setup is on.
* **"Default" ruleset** (public repositories only; the free plan has no rulesets on private ones): on the default branch, no deletion or force pushes, linear history, signed commits, pull requests (squash or rebase, no approvals required). Org and repository admins can bypass it.

New repositories are created from [`repo-template`](https://github.com/hononeko/repo-template). Removing a repository from `repos.tf` archives it.

## Adding a repository

1. Add an entry to `local.repos` in `repos.tf`. An empty entry gets the standard:

   ```hcl
   my-service = {
     description = "What it does"
   }
   ```

   Set `visibility = "private"` for a private repository, or `template = null` to create it empty instead of from `repo-template`.
2. Open a pull request. CI checks formatting and validates the configuration.
3. After merging, run `tofu plan` from `main`, check that it only creates the new repository, then `tofu apply`.

Add required status checks (`ruleset.status_checks`) in a later pull request, once the repository's CI has run and the check names exist. Until a required check reports, pull requests can't be merged.

## Customizing a repository

Add the settings that differ to its entry in `repos.tf`. See `modules/repository/variables.tf` for every option. For example:

```hcl
my-service = {
  description = "What it does"
  ruleset = {
    status_checks = local.image_checks
    code_scanning = local.codeql
  }
}
```

## Usage

State is stored on SeaweedFS (`s3.kerrlab.app`) and encrypted client-side.

```sh
cp backend.tfbackend.example backend.tfbackend

export TF_VAR_tofu_encryption_passphrase=$(pass tofu/github/encryption_passphrase)
export GITHUB_TOKEN=$(gh auth token)

tofu init -backend-config=backend.tfbackend
tofu plan
tofu apply
```

S3 credentials come from the `seaweedfs` profile in `~/.aws/credentials` (keys in `pass` at `cluster/s3/`). `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` in the environment take precedence over it.

The passphrase is also stored in OpenBao at `secret/tofu/github`. Without it the state can't be decrypted.

Private vulnerability reporting isn't supported by the provider and is enabled through `gh api`, so `gh` must be installed.

CI only checks formatting and validates the configuration. Apply runs locally.

## Development

Enable the commit-msg hook, which enforces [Conventional Commits](https://www.conventionalcommits.org/):

```sh
git config core.hooksPath .githooks
```
