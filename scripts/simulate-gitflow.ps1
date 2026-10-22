[CmdletBinding()]
param(
    [string]$Workspace = (Join-Path $PSScriptRoot "..\demo-repository")
)

$ErrorActionPreference = "Stop"

function Invoke-Git {
    param([Parameter(Position = 0, ValueFromRemainingArguments = $true)][string[]]$GitArgs)
    & git @GitArgs
    if ($LASTEXITCODE -ne 0) {
        throw "git $($GitArgs -join ' ') failed with exit code $LASTEXITCODE."
    }
}

function Write-ProjectFile {
    param([string]$RelativePath, [string]$Content)
    $target = Join-Path $Workspace $RelativePath
    $parent = Split-Path -Parent $target
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    [System.IO.File]::WriteAllText($target, $Content.Replace("`n", [Environment]::NewLine), (New-Object System.Text.UTF8Encoding($false)))
}

if (Test-Path -LiteralPath $Workspace) {
    throw "Workspace already exists: $Workspace`nChoose a new -Workspace path; this script will not overwrite an existing folder."
}

$Workspace = [System.IO.Path]::GetFullPath($Workspace)
New-Item -ItemType Directory -Path $Workspace | Out-Null
Push-Location $Workspace

try {
    Invoke-Git init -b main
    Invoke-Git config user.name "Gitflow Demo"
    Invoke-Git config user.email "gitflow-demo@example.invalid"
    Invoke-Git config tag.gpgSign false

    Write-ProjectFile ".gitignore" @'
node_modules/
'@
    Write-ProjectFile "package.json" @'
{
  "name": "welcome-service",
  "version": "0.1.0",
  "private": true,
  "scripts": { "test": "node --test" }
}
'@
    Write-ProjectFile "CHANGELOG.md" @'
# Changelog

## Unreleased
'@
    Write-ProjectFile "src/message.js" @'
function getWelcomeMessage() {
  return "Welcome!";
}

module.exports = { getWelcomeMessage };
'@
    Write-ProjectFile "src/message.test.js" @'
const test = require("node:test");
const assert = require("node:assert/strict");
const { getWelcomeMessage } = require("./message");

test("returns the original greeting", () => {
  assert.equal(getWelcomeMessage(), "Welcome!");
});
'@
    Write-ProjectFile ".githooks/pre-commit" @'
#!/usr/bin/env sh
set -eu

if git diff --cached --name-only | grep -Eq '(^|/)src/'; then
  if ! git diff --cached --name-only | grep -qx 'CHANGELOG.md'; then
    echo "Commit rejected: source changes must include an update to CHANGELOG.md." >&2
    exit 1
  fi
fi

npm test
'@
    Invoke-Git config core.hooksPath .githooks
    Invoke-Git add .
    Invoke-Git commit -m "chore: initialize welcome service"

    # Long-lived integration branch.
    Invoke-Git checkout -b develop

    # Feature branch and accepted PR #1.
    Invoke-Git checkout -b feature/welcome-endpoint
    Write-ProjectFile "src/message.js" @'
function getWelcomeMessage(name = "team") {
  return `Welcome, ${name}!`;
}

module.exports = { getWelcomeMessage };
'@
    Write-ProjectFile "src/message.test.js" @'
const test = require("node:test");
const assert = require("node:assert/strict");
const { getWelcomeMessage } = require("./message");

test("returns a personalized greeting", () => {
  assert.equal(getWelcomeMessage("Ada"), "Welcome, Ada!");
});
'@
    Write-ProjectFile "CHANGELOG.md" @'
# Changelog

## Unreleased

### Added
- Personalized welcome messages.
'@
    Invoke-Git add src CHANGELOG.md
    Invoke-Git commit -m "feat: personalize welcome messages"
    Invoke-Git checkout develop
    Invoke-Git merge --no-ff feature/welcome-endpoint -m "Merge pull request #1 from feature/welcome-endpoint"

    # Release preparation, production merge, tag, and merge-back.
    Invoke-Git checkout -b release/1.0.0
    Write-ProjectFile "package.json" @'
{
  "name": "welcome-service",
  "version": "1.0.0",
  "private": true,
  "scripts": { "test": "node --test" }
}
'@
    Write-ProjectFile "CHANGELOG.md" @'
# Changelog

## 1.0.0

### Added
- Personalized welcome messages.
'@
    Invoke-Git add package.json CHANGELOG.md
    Invoke-Git commit -m "chore(release): prepare 1.0.0"
    Invoke-Git checkout main
    Invoke-Git merge --no-ff release/1.0.0 -m "Merge release/1.0.0 into main"
    Invoke-Git tag -a v1.0.0 -m "Release 1.0.0"
    Invoke-Git checkout develop
    Invoke-Git merge --no-ff release/1.0.0 -m "Merge release/1.0.0 back into develop"

    # Emergency production fix and merge-back to both long-lived branches.
    Invoke-Git checkout main
    Invoke-Git checkout -b hotfix/1.0.1
    Write-ProjectFile "src/message.js" @'
function getWelcomeMessage(name = "team") {
  const safeName = String(name).trim() || "team";
  return `Welcome, ${safeName}!`;
}

module.exports = { getWelcomeMessage };
'@
    Write-ProjectFile "src/message.test.js" @'
const test = require("node:test");
const assert = require("node:assert/strict");
const { getWelcomeMessage } = require("./message");

test("returns a personalized greeting", () => {
  assert.equal(getWelcomeMessage("Ada"), "Welcome, Ada!");
});

test("falls back to team for blank names", () => {
  assert.equal(getWelcomeMessage("   "), "Welcome, team!");
});
'@
    Write-ProjectFile "package.json" @'
{
  "name": "welcome-service",
  "version": "1.0.1",
  "private": true,
  "scripts": { "test": "node --test" }
}
'@
    Write-ProjectFile "CHANGELOG.md" @'
# Changelog

## 1.0.1

### Fixed
- Blank names now fall back to `team`.

## 1.0.0

### Added
- Personalized welcome messages.
'@
    Invoke-Git add src package.json CHANGELOG.md
    Invoke-Git commit -m "fix: handle blank welcome names"
    Invoke-Git checkout main
    Invoke-Git merge --no-ff hotfix/1.0.1 -m "Merge hotfix/1.0.1 into main"
    Invoke-Git tag -a v1.0.1 -m "Release 1.0.1"
    Invoke-Git checkout develop
    Invoke-Git merge --no-ff hotfix/1.0.1 -m "Merge hotfix/1.0.1 back into develop"

    npm test
    Write-Host "Gitflow simulation complete: $Workspace" -ForegroundColor Green
    Write-Host "Inspect it with: git log --graph --oneline --decorate --all"
}
finally {
    Pop-Location
}
