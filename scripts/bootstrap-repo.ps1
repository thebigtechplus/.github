# Bootstrap one thebigtechplus repository (labels, CODEOWNERS, teams, merge + branch rules).
# Does NOT apply to all repos — pass the repo name each time.
#
# Usage:
#   pwsh ./scripts/bootstrap-repo.ps1 <repo-name>
#   pwsh ./scripts/bootstrap-repo.ps1 <repo-name> -Create
#
# Requires: gh (authenticated), PowerShell 5+ or PowerShell 7+
# Platforms: Windows, macOS, Linux (pwsh)

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Repo,

    [switch]$Create,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

$Org = "thebigtechplus"
$DevelopersTeam = "developers"
$AdminsTeam = "admins"
$CodeownersBody = "* @thebigtechplus/developers`n"

function Show-Usage {
    @"
Usage: bootstrap-repo.ps1 <repo-name> [-Create]

  <repo-name>   Repository name only (not owner/name). Example: api
  -Create       Create a private repo under thebigtechplus if it does not exist

This configures ONE repository. It does not cascade to other or future repos.
"@
}

if ($Help -or [string]::IsNullOrWhiteSpace($Repo)) {
    Show-Usage
    if ($Help) { exit 0 }
    exit 1
}

if ($Repo -match "/") {
    throw "Pass the repo name only (got '$Repo'). Example: api"
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "gh CLI not found. Install: https://cli.github.com/"
}

gh auth status 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "gh is not authenticated. Run: gh auth login"
}

$Full = "$Org/$Repo"

gh repo view $Full 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "→ repository exists: $Full"
} elseif ($Create) {
    Write-Host "→ creating private repository: $Full"
    gh repo create $Full --private --default-branch main --confirm
    if ($LASTEXITCODE -ne 0) { throw "failed to create $Full" }
} else {
    throw "repository $Full not found. Re-run with -Create, or create it first."
}

Write-Host "→ ensuring labels"
gh label create bug --repo $Full --color d73a4a --description "Something isn't working" --force | Out-Null
gh label create enhancement --repo $Full --color a2eeef --description "New feature or request" --force | Out-Null
gh label create dependencies --repo $Full --color 0366d6 --description "Dependency updates" --force | Out-Null
gh label create github-actions --repo $Full --color 2088FF --description "GitHub Actions related" --force | Out-Null

Write-Host "→ ensuring CODEOWNERS"
$bytes = [System.Text.Encoding]::UTF8.GetBytes($CodeownersBody)
$contentB64 = [Convert]::ToBase64String($bytes)

$sha = $null
try {
    $sha = gh api "repos/$Full/contents/CODEOWNERS" --jq .sha 2>$null
} catch {
    $sha = $null
}

if ($sha) {
    gh api -X PUT "repos/$Full/contents/CODEOWNERS" `
        -f message="chore: update CODEOWNERS" `
        -f content="$contentB64" `
        -f sha="$sha" | Out-Null
} else {
    gh api -X PUT "repos/$Full/contents/CODEOWNERS" `
        -f message="chore: add CODEOWNERS" `
        -f content="$contentB64" | Out-Null
}

Write-Host "→ team access (developers: write, admins: admin)"
'{"permission":"push"}' | gh api -X PUT "orgs/$Org/teams/$DevelopersTeam/repos/$Full" --input - | Out-Null
'{"permission":"admin"}' | gh api -X PUT "orgs/$Org/teams/$AdminsTeam/repos/$Full" --input - | Out-Null

Write-Host "→ merge settings (squash only)"
@'
{
  "allow_squash_merge": true,
  "allow_merge_commit": false,
  "allow_rebase_merge": false,
  "delete_branch_on_merge": true,
  "has_wiki": false
}
'@ | gh api -X PATCH "repos/$Full" --input - | Out-Null

Write-Host "→ branch protection on main"
$protectJson = @'
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": 1
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
'@

$protectOut = $protectJson | gh api -X PUT "repos/$Full/branches/main/protection" --input - 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Could not fully set branch protection (common on GitHub Free private repos)."
    Write-Warning "Apply what you can under Settings → Branches for $Full."
    Write-Host $protectOut
} else {
    Write-Host "→ branch protection applied"
}

Write-Host ""
Write-Host "Done: $Full"
Write-Host "Inherited from org .github (if this repo has no local ISSUE_TEMPLATE): issue/PR templates + community docs."
Write-Host "Smoke-check: open New issue on https://github.com/$Full/issues/new/choose"
