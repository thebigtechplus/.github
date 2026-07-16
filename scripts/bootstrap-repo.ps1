# Bootstrap one thebigtechplus repository (labels, CODEOWNERS, teams, merge + branch rules).
# Does NOT apply to all repos — pass the repo name each time.
#
# Usage:
#   pwsh ./scripts/bootstrap-repo.ps1 <repo-name>
#   pwsh ./scripts/bootstrap-repo.ps1 <repo-name> -Create
#
# Requires: GitHub CLI (gh), authenticated — required for all BigTech+ developers
# Platforms: Windows (PowerShell 5+ / pwsh), also works on macOS/Linux with pwsh
#
# Prefer from anywhere:
#   gh extension install thebigtechplus/gh-bootstrap-repo
#   gh bootstrap-repo <repo-name> [-Create] [-Public]
#
# Or download then run:
#   Invoke-RestMethod ... -OutFile bootstrap.ps1; pwsh -File bootstrap.ps1 <repo> -Create

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Repo,

    [switch]$Create,
    [switch]$Public,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

$Org = "thebigtechplus"
$TemplateRepo = "thebigtechplus/.github"
$DevelopersTeam = "developers"
$AdminsTeam = "admins"
$CodeownersBody = "* @thebigtechplus/admins`n"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Get-TemplateContent {
    param([string]$Name)
    $localPath = Join-Path $ScriptDir "templates/$Name"
    if (Test-Path $localPath) {
        return Get-Content -Raw -Path $localPath
    }
    $b64 = gh api "repos/$TemplateRepo/contents/scripts/templates/$Name" --jq .content 2>$null
    if ($LASTEXITCODE -ne 0) { throw "failed to fetch template $Name" }
    $bytes = [Convert]::FromBase64String(($b64 -replace "`n", ""))
    return [System.Text.Encoding]::UTF8.GetString($bytes)
}

function Ensure-RepoFileIfMissing {
    param(
        [string]$Path,
        [string]$Content,
        [string]$Message
    )
    gh api "repos/$Full/contents/$Path" --jq .sha 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  skipped ($Path exists)"
        return
    }
    $contentB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Content))
    gh api -X PUT "repos/$Full/contents/$Path" `
        -f message="$Message" `
        -f content="$contentB64" | Out-Null
    Write-Host "  added $Path"
}

function Seed-RepoTemplates {
    $readme = (Get-TemplateContent "README.md") -replace '\{\{REPO\}\}', $Repo
    $agents = Get-TemplateContent "AGENTS.md"
    $claude = Get-TemplateContent "CLAUDE.md"

    Write-Host "→ ensuring README.md"
    Ensure-RepoFileIfMissing -Path "README.md" -Content $readme -Message "docs: add README from org template"

    Write-Host "→ ensuring AGENTS.md"
    Ensure-RepoFileIfMissing -Path "AGENTS.md" -Content $agents -Message "docs: add AGENTS.md from org template"

    Write-Host "→ ensuring CLAUDE.md"
    Ensure-RepoFileIfMissing -Path "CLAUDE.md" -Content $claude -Message "docs: add CLAUDE.md from org template"
}

function Show-Usage {
    @"
Usage: bootstrap-repo.ps1 <repo-name> [-Create] [-Public]

  <repo-name>   Repository name only (not owner/name). Example: api
  -Create       Create the repo under thebigtechplus if it does not exist (private by default)
  -Public       With -Create, create a public repo instead of private

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

if ($Public -and -not $Create) {
    throw "-Public requires -Create"
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
    if ($Public) {
        Write-Host "→ creating public repository: $Full"
        gh repo create $Full --public
    } else {
        Write-Host "→ creating private repository: $Full"
        gh repo create $Full --private
    }
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

Write-Host "→ team access (developers: write, admins: admin; reviews via CODEOWNERS → admins)"
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

Seed-RepoTemplates

function Show-BranchProtectionGuide {
    Write-Host ""
    Write-Host "→ branch protection: configure manually in the web UI"
    Write-Host "  Bootstrap does not set branch protection (GitHub Free private org repos require Team)."
    Write-Host ""
    Write-Host "  Open: https://github.com/$Full/settings/rules"
    Write-Host ""
    Write-Host "  Add a branch ruleset (or classic rule) for branch 'main' with:"
    Write-Host ""
    Write-Host "  - Require a pull request before merging"
    Write-Host "  - Required approvals: 1"
    Write-Host "  - Require review from Code Owners (after CODEOWNERS is in place)"
    Write-Host "  - Dismiss stale pull request approvals when new commits are pushed"
    Write-Host "  - Require conversation resolution before merging"
    Write-Host "  - Restrict force pushes"
    Write-Host "  - Restrict deletions"
    Write-Host ""
    Write-Host "  On GitHub Free, these options may be unavailable for private repositories"
    Write-Host "  until the organization upgrades to GitHub Team, or the repository is public."
    Write-Host ""
    Write-Host "  Docs: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches"
}

Show-BranchProtectionGuide

Write-Host ""
Write-Host "Done: $Full"
Write-Host "Inherited from org .github (if this repo has no local ISSUE_TEMPLATE): issue/PR templates + community docs."
Write-Host "Smoke-check: open New issue on https://github.com/$Full/issues/new/choose"
