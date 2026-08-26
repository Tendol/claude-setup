---
name: weekly-alert-triage
description: Use when auditing a week of Datadog alerts in a Slack alert channel (#acquisition-alerts) to decide what becomes a GitHub issue. Triggers on "/weekly-alert-triage", "audit the datadog alerts", "triage last week's alerts", "what fired in acquisition-alerts", "weekly error review", or a recurring Monday alert-review ritual.
---

# weekly-alert-triage

Turn a week of noisy Datadog alert traffic into a short, deduped list of issues worth
filing. The channel is the input; a signed-off triage table and a handful of GitHub
issues are the output.

## Core principle

**Alert messages are not incidents.** A flapping monitor emits two messages per episode
(trigger + recover) and can produce 20+ messages from one unresolved problem. Count
episodes, not messages, or the loudest monitor wins the whole audit.

## When to Use

- Weekly (or ad-hoc) review of `#acquisition-alerts`
- User asks "what's been firing", "audit the alerts", "triage last week"
- Before sprint planning, to convert prod noise into backlog

**Do NOT use for:** debugging one specific failure (use `datadog-investigate` mode 1),
or explaining a single spike (mode 3). This skill is about *breadth then disposition*.

## Prerequisites

| Need | Check | Fix |
|------|-------|-----|
| Slack MCP | `slack_search_channels` works | reconnect in `/mcp` |
| Datadog MCP (optional, for log-level depth) | `search_datadog_logs` in tool list | user runs `/mcp` → "claude.ai Datadog" |
| `gh` project scope | `gh auth status \| grep -i "token scopes"` | `gh auth refresh -s project` |

**Datadog auth is optional, not blocking.** Without it you can still complete the full
alert-level audit from Slack. What you lose is the log-level root cause ("what *are*
those 60 errors"). Say explicitly which findings are alert-level only — never guess at
log contents you could not read.

## Workflow

### Step 1 — Pull the week from Slack

Channel `#acquisition-alerts` = `C06FSG3QQBX`.

```
slack_read_channel(channel_id="C06FSG3QQBX", oldest=<unix ts 7d ago>,
                   limit=100, response_format="detailed")
```

Get the timestamp with `date -u -j -f "%Y-%m-%d %H:%M:%S" "<date> 00:00:00" +%s` (macOS).

**Two traps here:**

1. `response_format: "concise"` returns **empty message bodies** for Datadog alerts —
   the entire alert lives in Slack *attachments*, which concise strips. It looks like the
   bot posted 30 blank messages. Always use `detailed`.
2. `detailed` output usually **exceeds the tool's token cap** and gets spilled to a file.
   That is fine — parse it with shell rather than re-reading it whole:

```bash
WORK=$(mktemp -d)                      # in a background job, use "$CLAUDE_JOB_DIR/tmp"
sed 's/\\n/\n/g' <saved-file> > "$WORK/alerts.txt"

# monitor tally
grep -oE 'Attachment: (Triggered|Warn|Recovered)[^(]*' "$WORK/alerts.txt" \
  | sed 's/ *$//' | sort | uniq -c | sort -rn

# timeline for episode pairing (Step 2)
grep -E '^=== Message|^Attachment: (Triggered|Warn|Recovered)' "$WORK/alerts.txt" \
  | sed 's/(https[^)]*)//' | cut -c1-110
```

### Step 2 — Collapse messages into episodes

For each distinct monitor, pair each `Triggered:`/`Warn:` with its following
`Recovered:`. Record per monitor: **episode count**, **how many reached critical**,
**first/last fire**, **longest open duration**, and whether episodes cluster (one bad
day) or spread (chronic).

**Duration matters more than count.** Two 8-hour overnight outages beat twelve 4-minute
flaps every time — and the raw message tally ranks them the other way round, which is why
this step exists.

### Step 3 — Separate severity tiers before reading anything into the numbers

`Warn:` and `Triggered:` are **two thresholds of the same monitor**, not two monitors and
not a config change. A Datadog monitor with a warning tier emits:

| Prefix | Meaning | Example text |
|--------|---------|--------------|
| `Warn:` | warning threshold crossed | `More than 60.0 log events matched…` |
| `Triggered:` | critical threshold crossed | `More than 100 log events matched…` |
| `Recovered:` | back under the warning threshold | `Less than or exactly 60.0 log events…` |

Seeing `60` on most messages and `100` on one looks exactly like someone retuned the
monitor mid-week. It is not. **Confirm the tier from the message prefix before claiming a
threshold changed** — a real config change shows up as the *same* prefix carrying a
different number.

This distinction drives priority: a monitor that warns eleven times but goes critical once
is mostly telling you its warning tier is chatty. Report warn-only and critical episode
counts separately.

Also capture from the alert body:
- `Tags:` line (`team:`, `service:`, `env:`)
- Any "managed in code" notice naming a source file, e.g.
  `wanderu/messaging .deploy/helm-chart/templates/monitor-*.yaml` — that monitor is
  fixed by a PR to that repo, **never** by editing the Datadog UI. Put the path in the issue.
- The Log Explorer URL — the issue needs it.

### Step 4 — Read every thread

Any alert with `Thread: N replies` already has human triage on it. Read it
(`slack_read_thread` with the parent `message_ts`).

Threads routinely contain the answer ("I don't see no-index in the captured response"),
an owner who has claimed it, or an issue someone already filed. **Filing an issue that a
thread already resolved is the most common failure of this audit.**

### Step 5 — Deepen with Datadog (only if authed)

For the top 2–3 monitors by episode count, pull the actual errors. Follow
`datadog-investigate` mode 2 (opportunities) — do not reinvent the query patterns:

```
filter: env:prod service:<svc> status:error
sql:    SELECT "@error.name", count(*) FROM logs
        GROUP BY "@error.name" ORDER BY count(*) DESC
```

Goal is one sentence per monitor: *what* the errors actually are and whether they are
ours to fix.

### Step 6 — Dedupe against open issues

```bash
gh search issues --owner wanderu --state open "<keyword>" --limit 8 \
  --json repository,number,title,updatedAt
```

Search the monitor's subject words, not its title. Record for each finding: no issue /
open issue #N (fresh) / open issue #N (stale, >30d untouched).

### Step 7 — Classify

| Situation | Disposition |
|-----------|-------------|
| Long outage (hours), no open issue | **File** — highest priority |
| ≥3 critical episodes, no open issue | **File** |
| Many warn-only episodes, all short, never critical | **File as monitor tuning** — the warn tier is chatty, not prod |
| Monitor fires at its recovered value (e.g. "0.0 events… baseline 0") | **File as monitor tuning** — the baseline is wrong |
| Open issue exists, fresh | **Comment** with this week's counts; do not duplicate |
| Open issue exists, stale | **Comment + flag for reprioritization** |
| Thread already explains and closes it | **No issue** — note it in the report |
| One fire, self-recovered, benign | **No issue** — watch next week |

### Step 8 — Present the table and STOP

Show the user before filing anything:

| Monitor | Episodes | Longest | Existing | Disposition | Why |
|---------|----------|---------|----------|-------------|-----|

**This is a hard gate. Never file issues from this skill without explicit sign-off.**
The audit is cheap to redo; a wave of duplicate issues is not.

### Step 9 — File approved issues

Non-interactive (this skill does not use `create-issue`'s editor flow — the body is
already written), but reuse its metadata contract:

```bash
gh issue create --repo wanderu/<repo> --title "<title>" \
  --body-file <file> --label "acquisition_team"
gh project item-add 11 --owner wanderu --url <issue_url>
```

Then set the issue type via GraphQL — see `create-issue` Step 6 for the mutation and the
type IDs (Bug `IT_kwDOAOgohs4AHiB_`, Task `IT_kwDOAOgohs4AHiB8`).

Repo routing: the service in the `Tags:` line owns the alert (`service:nexus` →
`wanderu/nexus`). Cross-cutting or investigation-only work goes to `wanderu/strategy`.

### Step 10 — Save the report

Write the full triage table to `~/.claude/session-notes/<YYYY-MM-DD>-alert-triage.md`.
Next week's run diffs against it — that is how "chronic vs. new" becomes answerable.

## Issue body template

```markdown
## Alert
[<Monitor name>](<datadog monitor URL>) — fired <N> times between <date> and <date>.
Longest open: <duration>.

## Signal
<What the errors are. If Datadog log access was unavailable, say so explicitly
rather than characterizing logs you did not read.>

- [Log Explorer](<url>)
- Tags: `service:<svc>` `env:prod` `team:acquisition`

## Prior discussion
<Link the Slack thread and summarize what was already established, or "none">

## Why this is worth fixing
<User/SEO/revenue impact. Overnight SEO outage != 4-minute client-error flap.>

## Notes
<If the monitor is managed in code, name the file — changes to the Datadog UI
are overwritten on the next deploy.>
```

## Common Mistakes

| Mistake | Consequence |
|---------|-------------|
| Reading the channel with `concise` | Alerts look empty; you audit nothing |
| Counting messages instead of episodes | One flapping monitor dominates the report |
| Ranking by count alone | An 8-hour SEO outage loses to twelve 4-minute flaps |
| Reading `Warn:` 60 vs `Triggered:` 100 as a config change | You report a threshold edit that never happened |
| Skipping threads | You file an issue a colleague already filed or already answered |
| Filing before sign-off | Duplicate-issue cleanup costs more than the audit saved |
| Describing log contents without Datadog access | Fabricated root cause |

## Red Flags — STOP

- About to `gh issue create` without having shown the user the triage table
- Writing "the errors are caused by…" when Datadog auth failed
- Claiming a threshold changed without checking the `Warn:`/`Triggered:` prefix
- Creating an issue whose subject already appears in `gh search issues` output
- Recommending a Datadog UI change for a monitor whose alert says "managed in code"
