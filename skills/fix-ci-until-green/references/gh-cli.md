# gh CLI Recipes for CI Triage

Everything here assumes `gh auth status` succeeds. Add `-R OWNER/REPO` to any command run outside
the target repository.

## Contents

- [Resolving a run](#resolving-a-run)
- [Reading results](#reading-results)
- [Getting more log than the report shows](#getting-more-log-than-the-report-shows)
- [Annotations via the API](#annotations-via-the-api)
- [Comparing against the last green run](#comparing-against-the-last-green-run)
- [Finding the run for a pushed commit](#finding-the-run-for-a-pushed-commit)
- [Pitfalls that produce misleading output](#pitfalls-that-produce-misleading-output)

## Resolving a run

URL shapes that all carry the same run ID:

```
https://github.com/OWNER/REPO/actions/runs/33040813794
https://github.com/OWNER/REPO/actions/runs/33040813794/job/98413753747
https://github.com/OWNER/REPO/actions/runs/33040813794/attempts/2
```

From other starting points:

```bash
gh pr checks 123                                   # a PR -> its check runs and their URLs
gh run list --branch my-branch --limit 10          # a branch -> recent runs
gh run list --commit "$(git rev-parse HEAD)"       # a commit -> its runs
gh run list --workflow ci.yml -s failure -L 5      # a workflow -> its recent failures
```

## Reading results

```bash
gh run view <run-id>                               # human summary
gh run view <run-id> --verbose                     # summary with per-step outcomes
gh run view <run-id> --json conclusion,status,headSha,headBranch,event,jobs
gh run view <run-id> --exit-status                 # non-zero if the run failed
```

A run may fail with **no failed job at all**. That means the failure is workflow-level: an invalid
workflow file, a bad `if:` expression, a missing required check, a cancelled dependency, or a
`startup_failure`. Read the workflow YAML rather than hunting for a log.

## Getting more log than the report shows

`scripts/ci_failure_report.sh` prints a window around each `##[error]`. When that is not enough:

```bash
gh run view --job <job-id> --log-failed             # failed steps only
gh run view --job <job-id> --log                    # the full job log
gh run view <run-id> --log                          # every job, usually far too large
```

Every line is prefixed `JOB<TAB>STEP<TAB>TIMESTAMP MESSAGE`. Strip the noise before reading:

```bash
gh run view --job <job-id> --log \
  | cut -f3- \
  | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:.]+Z //' \
  | grep -n -B 60 -A 10 'FAILED'
```

Slice a specific step out of a job log by its step column:

```bash
gh run view --job <job-id> --log | awk -F'\t' '$2 == "Run pytest"' | cut -f3-
```

For a rerun run, `--attempt N` on both `gh run view` and the report script targets one attempt.

## Annotations via the API

Annotations are the structured version of the error markers and often name the exact file and line:

```bash
gh api "repos/{owner}/{repo}/check-runs/<job-id>/annotations" \
  --jq '.[] | "\(.annotation_level) \(.path):\(.start_line) \(.message)"'
```

Job-level metadata not exposed by `gh run view`:

```bash
gh api "repos/{owner}/{repo}/actions/jobs/<job-id>" \
  --jq '{name, conclusion, runner_name, labels, started_at, completed_at}'
```

## Comparing against the last green run

The single most useful triage move when a job "used to work": find what changed between the last
green run and this one.

```bash
LAST_GREEN=$(gh run list --workflow ci.yml --branch main -s success -L 1 --json headSha -q '.[0].headSha')
git log --oneline "$LAST_GREEN..HEAD"
git diff "$LAST_GREEN..HEAD" -- .github/workflows/
```

If the diff is empty, the code did not change — the environment did. Suspect a floating action tag,
an unpinned base image, a `latest` dependency, a runner image rollout, or an expired credential.

## Finding the run for a pushed commit

```bash
gh run list --commit <sha> --json databaseId,workflowName,status,conclusion,url
gh run watch <run-id> --exit-status          # blocks on one run; the wait script handles all of them
```

`scripts/wait_for_ci.sh` wraps the polling for every run attached to the commit.

When no run appears for a pushed SHA, work through these in order:

1. Path or branch filters in `on:` exclude the change.
2. The workflow needs approval — fork PRs, or a first-time contributor.
3. The event attaches the run to a different SHA: `merge_group` uses the merge-queue commit and
   `pull_request_target` uses the base. Fall back to `gh run list --branch <branch>`.
4. The workflow is disabled: `gh workflow list --all`.
5. The workflow file itself is invalid, so no run was ever created.

## Pitfalls that produce misleading output

- **Logs expire after 90 days.** Older runs return empty logs; the annotations API may still answer.
- **`--log-failed` can return the entire job log** with the step column showing `UNKNOWN STEP`, when
  GitHub cannot map log lines to steps. Do not assume everything printed is the failing step.
- **The tail of a job log is post-job cleanup**, not the error. Anchor on `##[error]` and read
  *backwards* from it.
- **`exit code 1` is not a diagnosis.** It is the shell reporting that something upstream in the same
  step failed; the real message is earlier in that step.
- **Secrets are masked as `***`.** A value that renders as `***` was set; a genuinely missing secret
  renders as an empty string.
- **`gh run rerun` is out of scope for this loop.** The loop treats every failure as a real defect.
- **`--commit` needs the full 40-character SHA.** An abbreviation matches nothing and is
  indistinguishable from "no run exists". `wait_for_ci.sh` expands short SHAs when the commit is
  present locally and refuses otherwise.
- **Rate limits**: `gh api rate_limit`. Pulling full logs for a large matrix burns quota fast — use
  the report script and fetch full logs only for the job being triaged.
