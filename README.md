# Gitflow Simulation

A self-contained, repeatable mini project that demonstrates a complete Gitflow-style delivery cycle:

`feature branch → pull request → merge → release → hotfix → merge back to develop → pre-commit hook`

The repository includes a tiny dependency-free Node.js module so that every change has a real test, a GitHub Actions workflow, and a PowerShell simulator that creates the complete, annotated Git history locally.

## What you will learn

- Keep ongoing work on `develop` while `main` only contains production-ready code.
- Create and merge a `feature/*` branch through a reviewable pull request.
- Stabilize a `release/*` branch, tag the production release, and merge it back into `develop`.
- Create a `hotfix/*` branch from `main`, tag its patch release, and merge it into both long-lived branches.
- Prevent source-code commits that omit a `CHANGELOG.md` update using a repository-managed pre-commit hook.

## Prerequisites

- Git 2.28+ (for `git init -b main`)
- Node.js 18+ (only used for the built-in test runner)
- PowerShell 7+ or Windows PowerShell 5.1

## Run the simulation

From this project folder:

```powershell
./scripts/simulate-gitflow.ps1
```

The script writes an entirely new repository to `demo-repository` beside this project. It never changes this template folder. To select a different location:

```powershell
./scripts/simulate-gitflow.ps1 -Workspace C:\Code\gitflow-demo
```

When it finishes, inspect the result:

```powershell
Set-Location ./demo-repository
git log --graph --oneline --decorate --all
git branch --all
git tag --list
npm test
```

## Branch and release map

| Stage | Branch | Outcome |
| --- | --- | --- |
| Feature | `feature/welcome-endpoint` | Adds personalized messages, then merges to `develop` as simulated PR #1. |
| Release | `release/1.0.0` | Prepares version 1.0.0, merges to `main`, tags `v1.0.0`, then merges back to `develop`. |
| Hotfix | `hotfix/1.0.1` | Fixes unsafe greeting input, merges to `main`, tags `v1.0.1`, then merges back to `develop`. |

The local merges intentionally use `--no-ff` with pull-request-style messages, making the graph easy to study even without a remote host.

## Pre-commit policy

The simulator configures `core.hooksPath` to `.githooks`. Its pre-commit hook runs the test suite and rejects any commit that stages a file in `src/` without staging `CHANGELOG.md` too.

Try it after running the simulator:

```powershell
Set-Location ./demo-repository
Add-Content src/message.js "`n// Try a change"
git add src/message.js
git commit -m "change greeting"
```

The commit is rejected. Stage a changelog entry as well, then commit again.

## Publish to GitHub

Create an empty GitHub repository (without a README, license, or `.gitignore`), then run the following from this project folder. Replace `YOUR-ACCOUNT` if needed.

```powershell
git init -b main
git add .
git commit -m "chore: add Gitflow simulation project"
git remote add origin https://github.com/YOUR-ACCOUNT/gitflow-simulation.git
git push -u origin main
```

After pushing, GitHub Actions will run the included test workflow. The generated `demo-repository` is intentionally excluded from version control.
