---
name: datadog-investigate
description: >
  Investigate issues using the Datadog MCP tools. Three modes: (1) debug a specific
  failed booking or request — "why did my dev booking fail", "debug my booking on
  branch X"; (2) find improvement opportunities — "what booking failures can we fix",
  "where are we losing revenue to errors"; (3) investigate a pattern over time —
  "why did we get 55 unknown booking failures last week", "what changed that caused
  error spikes". Use this skill whenever the user wants to query Datadog to understand
  failures, errors, patterns, or opportunities in any Wanderu service — not just
  bookings. Trigger on phrases like "check datadog", "why did X fail", "what's
  failing in prod", "debug my dev booking", "error analysis", "investigate errors",
  "booking failures", or any request to look at logs/spans/traces for debugging.
---

# Datadog Investigate

A skill for investigating issues, debugging failures, and finding improvement
opportunities using Datadog MCP tools.

## Determine the mode

The user's request maps to one of three investigation modes. Read their intent
and pick the right one:

| Mode | User is asking... | Examples |
|------|-------------------|----------|
| **debug** | "Why did this specific thing fail?" | "why did my dev booking fail", "debug my booking on branch fix/foo" |
| **opportunities** | "Where can we improve?" | "what booking failures can we fix", "where are we losing money to errors" |
| **investigate** | "Why did this pattern happen?" | "why did we get 55 unknown failures last week", "what caused the error spike on Tuesday" |

If the mode isn't obvious, ask. Don't guess — the query strategy differs significantly.

---

## Wanderu environment reference

Use these when building Datadog queries. Don't hardcode — the user might be asking
about any service, but these are the most common.

### Environments
- **Dev**: `env:dev`, cluster `wanderu-dev`
- **Prod**: `env:prod`, cluster `wanderu-prod`
- **Pilot**: `env:pilot`

### Booking-path services
The booking flow is: **ui-react** (or canopy/nexus) -> **wapi** -> **wtix** -> **pservs** (carrier proxy).
Cortex is NOT in the booking path.

| Service | Role |
|---------|------|
| `ui-react` | Legacy frontend |
| `canopy` | New frontend |
| `wapi` | API gateway |
| `wtix` / `wtix-server` | Booking engine |
| `wtix-processor` | Async ticket processing |
| `wtix-generator` | Ticket generation |
| `papi` | Pricing API |
| `pservs` | Carrier proxy (Python) |
| `orders` / `orders-consumer` | Order management |
| `payment-service` | Payments |

### Version/build tagging
All builds follow the pattern `YYYY.M.D-sha<short-hash>` (e.g., `2026.4.3-sha2e34d9a`).
Branch builds in dev use the same format — differentiated by the git sha, not a
branch name tag. To find a specific branch build, either:
- Ask the user for the sha or version tag
- Search spans/logs for the git sha: `@git.commit.sha:<sha>`
- Look at recent versions: `version:*sha<partial>*`

### Key error attributes in logs
- `error.code` — numeric (260, 280) or string (PAYMENT_FAILURE, UNKNOWN)
- `error.errorCategory` — e.g., FUNDING_ERROR
- `error.errorCode` — e.g., PAYMENT_FAILURE, UNKNOWN
- `error.name` — error class (SessionDoesNotExistError, etc.)
- `error.message` — human-readable description
- `error.stack` — full stack trace
- `responseBody.error.statusCode` — HTTP status code

### Common booking error patterns
- **Session errors**: code 260 (doesn't exist), 280 (already exists)
- **Payment/funding errors**: PAYMENT_FAILURE, UNKNOWN under FUNDING_ERROR category
- **Carrier booking failures**: error codes like 706 (price mismatch), 7214 (validation),
  600 (connection lost) — these come from pservs
- **HTTP errors in wapi**: 4xx/5xx from upstream services

---

## Mode 1: Debug a specific failure

The user had something fail and wants to know why. Usually a dev booking, but could
be any request in any environment.

### Step 1: Gather context

Ask for (or infer from conversation) what you need:
- **What failed?** Booking, search, payment, etc.
- **When?** "Just now", "this morning", "yesterday around 3pm"
- **Environment?** Dev or prod (default to dev for "my booking")
- **Branch/version?** If dev, ask if they were on a specific branch build. Get the
  sha or branch name if possible.
- **Any identifiers?** Session ID, trace ID, order ID, error message they saw

### Step 2: Find the failure

Start broad, narrow down. The goal is to find the specific error log or trace.

**If you have a trace ID or session ID**, go straight to it:
- `search_datadog_spans` with the trace ID
- `search_datadog_logs` filtering by session ID in the message

**If you know the approximate time and service**, search error logs:
```
filter: env:dev service:wtix status:error
from: <approximate time>
```

**If the user specified a branch**, filter by version/sha:
```
filter: env:dev service:wtix version:<version-tag>
```
or search spans with `@git.commit.sha:<sha>`.

**If you only know "my dev booking failed recently"**, cast a wider net across
booking-path services:
```
filter: env:dev (service:wtix OR service:wapi OR service:pservs) status:error
from: now-1h
```

### Step 3: Trace the request flow

Once you find the error, trace it through the stack:
1. Get the trace ID from the error log/span
2. Use `get_datadog_trace` to see the full request flow
3. Identify which service actually caused the failure (the deepest error in the trace)
4. Read the error details — stack trace, error code, carrier response if applicable

### Step 4: Explain the root cause

Present findings clearly:
- **What happened**: The specific error and where it occurred
- **Why it happened**: Root cause if determinable (carrier rejected, validation failed,
  service down, etc.)
- **What to do**: Concrete next step — fix code, check carrier config, retry, etc.

If the failure is in pservs (carrier proxy), note which carrier and what the carrier
returned — this is usually the actionable information.

---

## Mode 2: Find improvement opportunities

The user wants to understand error patterns and find things worth fixing. This is
an analytical mode — you're looking for patterns, not debugging a single failure.

### Step 1: Scope the analysis

Clarify:
- **What area?** Bookings, payments, searches, a specific carrier, etc.
- **Environment?** Almost always prod for opportunity analysis
- **Time range?** Default to 7 days for a good sample. Use `now-7d` to `now`.

### Step 2: Get the error landscape

Start with a high-level breakdown of errors by type/code:

```sql
-- Top error codes/categories
SELECT "@error.code", "@error.errorCategory", count(*)
FROM logs
GROUP BY "@error.code", "@error.errorCategory"
ORDER BY count(*) DESC
LIMIT 20
```

Then break down by service and by time to see trends:

```sql
-- Error volume by service
SELECT service, count(*)
FROM logs
GROUP BY service
ORDER BY count(*) DESC

-- Daily trend
SELECT DATE_TRUNC('day', timestamp), count(*)
FROM logs
GROUP BY DATE_TRUNC('day', timestamp)
ORDER BY DATE_TRUNC('day', timestamp)
```

Use `extra_columns` to add `@error.code`, `@error.errorCategory`, `@error.errorCode`,
`@error.name` as needed.

### Step 3: Quantify each opportunity

For each significant error pattern, estimate impact:
- **Volume**: errors per day/week
- **Revenue impact**: if it's a booking failure, estimate lost revenue
  (avg ticket ~$50, use the actual error-to-lost-booking ratio if known)
- **User impact**: does the user see an error, or is it silent/retried?
- **Fixability**: is this something we control, or a carrier/external issue?

### Step 4: Drill into top opportunities

For the top 3-5 error patterns by volume or impact:
1. Look at sample error logs to understand the specific failure
2. Identify the root cause pattern
3. Check if it's carrier-specific (group by carrier if applicable)
4. Note if there's a trend (increasing, stable, decreasing)

### Step 5: Present recommendations

Rank opportunities by estimated impact and present as a table:

| Priority | Error pattern | Volume/week | Est. impact | Root cause | Fix |
|----------|--------------|-------------|-------------|------------|-----|
| 1 | ... | ... | ... | ... | ... |

For each recommendation, be specific about what code/config change would fix it
and which repo/service is involved.

---

## Mode 3: Investigate a pattern over time

The user noticed something specific and wants to understand why it happened. They
typically have a specific error type and a time range.

### Step 1: Define the investigation

Get clear on:
- **What pattern?** "55 unknown booking failures", "spike in 500s", "increase in
  session errors"
- **Time range?** "Last week", "over the past 3 days", "since Tuesday"
- **Baseline expectation?** What would they expect normally? (helps determine if
  this is a spike vs. steady state)

### Step 2: Confirm the numbers

First, reproduce the count the user mentioned and validate it:

```sql
SELECT count(*) FROM logs
-- with appropriate filter for the error pattern and time range
```

Then break it down by day/hour to see the shape of the pattern:

```sql
SELECT DATE_TRUNC('hour', timestamp), count(*)
FROM logs
GROUP BY DATE_TRUNC('hour', timestamp)
ORDER BY DATE_TRUNC('hour', timestamp)
```

Is it a spike? Gradual increase? Steady? This shapes the investigation.

### Step 3: Correlate with changes

**If it's a spike** (concentrated in time):
- Check what version was deployed around that time
- Look for deploy events: `search_datadog_events` with deploy/release keywords
- Compare error rate before vs. during vs. after the spike
- Check if a specific host/pod is responsible

**If it's a gradual increase**:
- Check if a new carrier or route was added
- Look for changes in traffic volume (more traffic = more errors, but rate matters)
- Compare error rate (errors/total requests) not just absolute count

**If it's steady state** (user just noticed it):
- This becomes more like an opportunity analysis — shift to Mode 2 thinking
- Focus on root cause and fixability rather than "what changed"

### Step 4: Break down by dimensions

Slice the errors to find the specific cause:

```sql
-- By carrier (if booking-related)
-- By error sub-type
-- By host/pod (infrastructure issue?)
-- By version (did a deploy cause it?)
-- By hour of day (time-dependent pattern?)
```

### Step 5: Present the story

Tell a coherent narrative:
1. **The pattern**: "You saw 55 UNKNOWN booking failures over 7 days"
2. **The shape**: "They're concentrated on Tuesday and Wednesday, ~20/day vs. normal ~5/day"
3. **The cause**: "A deploy on Tuesday morning introduced version X which changed how
   carrier Y's timeout responses are handled"
4. **The evidence**: Link to specific logs, traces, or the Datadog explorer URL
5. **The recommendation**: What to do about it

---

## Query patterns cheat sheet

These are reliable Datadog query patterns for Wanderu. Adapt as needed.

### Logs (analyze_datadog_logs)

Always specify `filter` for the Datadog search query and `sql_query` for aggregation.
Use `extra_columns` to add custom attributes to the SQL schema.

```
# Error breakdown by code
filter: env:prod service:wtix status:error
extra_columns: [{"name": "@error.code", "type": "string"}, {"name": "@error.errorCategory", "type": "string"}]
sql: SELECT "@error.code", "@error.errorCategory", count(*) FROM logs GROUP BY "@error.code", "@error.errorCategory" ORDER BY count(*) DESC

# Error trend by hour
filter: env:prod service:wtix status:error
sql: SELECT DATE_TRUNC('hour', timestamp), count(*) FROM logs GROUP BY DATE_TRUNC('hour', timestamp) ORDER BY DATE_TRUNC('hour', timestamp)

# Errors by version (to find if a deploy caused issues)
filter: env:prod service:wtix status:error
sql: SELECT version, count(*) FROM logs GROUP BY version ORDER BY count(*) DESC
```

### Logs (search_datadog_logs)

Use for raw log inspection and attribute discovery. Use `extra_fields` to discover
what attributes are available before using them in `analyze_datadog_logs`.

```
# Discover available error attributes
query: env:prod service:wtix status:error
extra_fields: ["error*", "booking*", "carrier*", "response*"]

# Find logs by session ID
query: env:dev service:wtix <session-id>

# Log patterns to see common error shapes
query: env:prod service:wtix status:error
use_log_patterns: true
```

### Spans (search_datadog_spans)

Use for APM trace data. Good for finding specific requests and seeing service interactions.

```
# Find error spans for a service
query: env:dev service:wtix status:error

# Filter by git sha (for branch builds)
query: env:dev service:wtix @git.commit.sha:<sha>

# Find slow requests
query: env:prod service:wtix @duration:>5000000000
```

### Traces (get_datadog_trace)

Use when you have a trace ID and want to see the full request flow. Set
`only_service_entry_spans: true` for large traces to get a summary first.

### Tips
- DDSQL requires every non-aggregated column in GROUP BY
- Column aliases can't be reused in WHERE/GROUP BY — repeat the expression
- Quote column names with special chars: `"@error.code"`
- Use `from`/`to` for time ranges, not SQL WHERE on timestamp
- Start with `search_datadog_logs` + `extra_fields: ["*"]` to discover attributes
  before writing SQL queries against them
