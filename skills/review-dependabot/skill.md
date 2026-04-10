---
name: review-dependabot
description: >
  Triage Dependabot PRs with risk assessment. Batch mode reviews all open PRs,
  single mode deep-dives one PR. Checks version bump type, CI status, changelog
  for breaking changes, pin conflicts, and direct usage. Use when the user says
  "review dependabot", "check dependabot PRs", "triage deps", or points at a
  specific Dependabot PR.
---

# Review Dependabot PRs

Assess Dependabot PRs for safe merge. Report only — no auto-merge or auto-approve.

## Blocklist

Deps that always get "investigate" regardless of bump type:

```
dbt-core, dbt-common, dbt-snowflake, snowflake-connector-python, meltano
```

Edit this list as the project evolves.

## Mode Selection

| User says | Mode |
|-----------|------|
| "review dependabot PRs" / "check dependabot" / "triage deps" | **Batch** — all open |
| "review dependabot PR #255" / specific PR | **Single** — one PR |

## Batch Mode

### Step 1: Fetch all open Dependabot PRs

```bash
gh pr list --author "app/dependabot" --state open --json number,title,url,createdAt,labels,statusCheckRollup,body --limit 50
```

### Step 2: Dispatch parallel agents (one per PR)

For each PR, dispatch an agent with the prompt below. Use `superpowers:dispatching-parallel-agents`
if available, otherwise dispatch agents manually in parallel.

Each agent runs the **Assessment Checks** (see below) and returns a structured result.

### Step 3: Collect and present results

Sort by verdict: **Investigate** first, then **Merge**, then **Skip**.

Present the triage table:

```markdown
| # | PR | Package | Bump | CI | Verdict | Reason |
|---|-----|---------|------|----|---------|--------|
| 1 | #255 | cryptography | 44.0.3→46.0.7 (major) | pass | Investigate | Major bump, breaking changes in changelog |
| 2 | #233 | deepdiff | 8.6.1→8.6.2 (patch) | pass | Merge | Clean patch, no breaking changes |
| 3 | #223 | dbt-core | 1.10.13→1.11.3 (minor) | fail | Investigate | Blocklisted, CI failing, pins conflict |
```

### Step 4: Expand detail sections for "Investigate" verdicts

For each PR with verdict "Investigate", show a detail section:

```markdown
### #255 — cryptography 44.0.3→46.0.7

**Why investigate:** Major version bump with breaking changes in changelog
**CI:** Passing
**Usage:** Direct — imported in src/seo_data_transformer_pipeline/services/
**Pin conflicts:** None
**Changelog highlights:**
- v45.0.0: Dropped support for OpenSSL < 3.0
- v46.0.0: Removed deprecated X509 methods
**Recommendation:** Grep for removed APIs before merging.
```

## Single Mode

### Step 1: Fetch PR metadata

```bash
gh pr view <number> --json number,title,url,body,statusCheckRollup,commits
```

### Step 2: Run all assessment checks

Run checks sequentially (no parallelism needed for one PR).

### Step 3: Present detail section

Show the full detail section (same format as batch mode's expanded sections).

## Assessment Checks

Run these 6 checks for every Dependabot PR:

### 1. Version Classification

Parse package name and old→new version from PR title (format: "Bump <pkg> from <old> to <new>").

Classify the bump:
- **Patch**: 0.0.x change (e.g., 8.6.1→8.6.2)
- **Minor**: 0.x.0 change (e.g., 1.10.0→1.11.0)
- **Major**: x.0.0 change (e.g., 44.0.3→46.0.7)

Major = investigate. Patch = likely safe. Minor = depends on other signals.

### 2. CI Status

```bash
gh pr checks <number> --json name,state,conclusion
```

Any failure or pending = investigate.

### 3. Blocklist Check

Compare package name against the blocklist. Match = investigate.

### 4. Pin Conflict Detection

Search the repo for explicit version pins of this package:

```bash
# Check these files for version pins
grep -rn "<package_name>" pyproject.toml dbt_project.yml requirements*.txt requirements*.in setup.cfg Taskfile.yml 2>/dev/null
```

If the package is pinned to a specific version (e.g., `dbt-core==1.10.13`) and the
Dependabot bump crosses that pin, flag the conflict with the specific file and line.

### 5. Direct vs Transitive Usage

```bash
# Check if package is directly imported
grep -rn "import <package>" src/ dbt/ 2>/dev/null
grep -rn "from <package>" src/ dbt/ 2>/dev/null
```

Note: package import names sometimes differ from pip names (e.g., `pyjwt` → `import jwt`).
Check the PR body for the actual package import name if different.

- **Direct import found** = higher risk, changes could affect our code
- **No direct import** = transitive dependency, lower risk

### 6. Changelog / Release Notes

Extract the source repo from the Dependabot PR body (it includes a link to the repo).

```bash
# Fetch releases between old and new version
gh api repos/<owner>/<repo>/releases --paginate --jq '.[].tag_name' | head -20
```

Then fetch release notes for versions between old and new:

```bash
gh api repos/<owner>/<repo>/releases/tags/<tag>  --jq '.body'
```

Scan release notes for keywords: **breaking**, **deprecated**, **removed**, **migration**,
**incompatible**, **drop**, **rename**.

Flag any hits as changelog highlights in the detail section.

If no GitHub releases exist, note "No changelog available — manual review recommended."

## Verdict Logic

| Condition | Verdict |
|-----------|---------|
| Patch + CI passes + not blocklisted + no pin conflicts + no breaking keywords | **Merge** |
| Any check flags a concern | **Investigate** |
| CI failing + PR older than 14 days + no recent updates | **Skip** |

## Rules

- **Report only** — never merge, approve, or comment on PRs
- Present the triage table before any detail sections
- Always include evidence (file paths, changelog excerpts, CI check names)
- If changelog fetch fails, say so — don't guess at breaking changes
- For blocklisted deps, still run all checks — the detail section should explain what changed
- Be direct about risk — "this will break dbt" not "you might want to consider"
