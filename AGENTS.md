# Agent runbook

This is the one safe process for any AI coding agent (or human) making a
change in this repository: **worktree → branch → verify → push → PR**. It
operationalizes README's ["Jira-to-GitHub
workflow"](README.md#jira-to-github-workflow) into concrete commands. Read
that section first for the *why*; this file is the *how*.

`CLAUDE.md` points here rather than duplicating this content — there is
exactly one version of this process to keep current.

## 0. Before anything else

- Read this file and README.md's "Jira-to-GitHub workflow" and "Quality
  checks" sections.
- Run `git status --short` and `git branch --show-current`. Do not assume
  the working directory is clean, and do not assume a Jira label or an
  older roadmap document is still accurate — verify against current `main`.
- Jira numbers are optional. Use a descriptive branch, commit and PR title
  for user-requested work without a Jira issue; never invent an issue number.

## 1. Worktree or direct branch — decide based on what's in the working tree

**If the current working directory is clean** (or only contains changes
that are already part of what you're about to commit) **and `main` is
already up to date or fast-forwardable to `origin/main`**:

```bash
git fetch origin
git checkout main
git merge --ff-only origin/main   # only if it reports a clean fast-forward
git checkout -b <type>/PREP-<number>-<short-slug>
```

**If the working directory has unrelated uncommitted changes, or you are
not certain they're safe to sit alongside your new branch** (e.g. someone
else's in-progress edits, a half-finished unrelated task): do not touch
them. Never run `checkout`, `pull`, `merge`, `rebase`, `reset`, `stash`, or
`clean` against that directory to "clear the way." Instead, isolate your
work in a separate worktree built from `origin/main`:

```bash
git fetch origin
git worktree add ../<repo-name>-PREP-<number> -b <type>/PREP-<number>-<short-slug> origin/main
cd ../<repo-name>-PREP-<number>
flutter pub get
```

Do all editing, testing, and committing there. The original directory's
uncommitted changes remain exactly as they were the whole time — nothing
about them is read, staged, or modified.

Branch name prefix: `feature`, `fix`, `chore`, `docs`, `ci`, `security`, or
`test` — whichever matches the change. Use a short kebab-case slug (for example `feature/ui-refresh`); include
`PREP-<number>` only when an existing Jira issue is supplied.

## 2. Implement the smallest complete change

Do exactly what the Jira acceptance criteria require — no unrelated
cleanup, no drive-by refactors, no scope creep "while I'm in here." If the
audit label says `DONE` but a real gap exists, add a regression test that
reproduces the gap and fix only that gap; don't rewrite working code.
Preserve the domain/repository/UI boundary (UI never reads JSON, SQLite,
StoreKit, or the network directly).

## 3. Verify — for real, every time

Run these and paste their actual output; never report a check as passing
without having run it in this session:

```bash
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
```

Plus whichever build the Jira acceptance criteria name (e.g.
`flutter build ios --release --no-codesign`). For a bug/regression fix,
reproduce the bug first — a failing test, or a controlled before/after
comparison in a disposable clone or probe file — then fix it, then
re-verify green. Remove any temporary probe files/branches immediately
after use; never leave them in the tree or commit them.

## 4. Stage precisely, then review before committing

```bash
git status --short
git add <only the files actually in scope for this task>
git diff --cached --name-only
git diff --cached
```

Read the staged diff. If anything you didn't intend to touch appears —
another task's file, a logic change alongside what should be a pure
formatting fix, anything resembling a secret — stop and do not commit.

## 5. Commit

```bash
git commit -m "$(cat <<'EOF'
<type>: <short summary> (PREP-<number>)

<why this change, and anything a reviewer needs to know that isn't
obvious from the diff>

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
EOF
)"
```

## 6. Push and open a PR

```bash
git push -u origin <branch>
```

Never push directly to `main`, never force-push. Open a PR with a descriptive title (include a Jira number only when supplied); GitHub auto-populates the description from
`.github/PULL_REQUEST_TEMPLATE.md` — fill in every section honestly
(Jira link, real test evidence, risks, privacy/accessibility decisions,
rollback plan). Do not merge it yourself; wait for required checks and
review.

## 7. After merge — cleanup, but verify first

Squash-merges break `git branch -d`'s ancestry check (it will refuse a
branch that GitHub already merged, because the SHAs differ). Before
deleting a local branch or worktree, confirm the merge independently:

```bash
git fetch origin
git diff <your-branch> origin/main   # must be empty (or scoped to your files, unchanged)
```

Only then:

```bash
git worktree remove ../<repo-name>-PREP-<number>   # if you used a worktree
git branch -D <type>/PREP-<number>-<short-slug>
```

Never delete a branch or worktree you haven't independently confirmed is
fully merged, and never delete anyone else's branch without being asked.

## Branch protection on `main`

**Current state: not server-enforced.** Every merge so far has gone
through a PR with green CI by convention (see `main`'s history), not
because GitHub rejects a direct push or a red check. Enabling this
requires repository admin access this environment does not have (no
`gh` CLI, no API token, and the constraint against ever storing or
printing one) — it remains an explicit, tracked manual step for whoever
holds that access:

**Via GitHub UI:** Settings → Branches → Add branch protection rule →
branch name pattern `main` → enable "Require a pull request before
merging", "Require status checks to pass before merging" (select
`quality` and `ios-build`; add `secret-scan` too once PREP-639 merges),
"Require branches to be up to date before merging", and "Do not allow
bypassing the above settings" (or an equivalent ruleset that also blocks
force-pushes and deletions).

**Equivalent `gh` command**, once authenticated with admin access:

```bash
gh api repos/anielka1/danb_rhs_prep/branches/main/protection \
  --method PUT \
  -f required_status_checks[strict]=true \
  -f 'required_status_checks[contexts][]=quality' \
  -f 'required_status_checks[contexts][]=ios-build' \
  -f required_pull_request_reviews[required_approving_review_count]=0 \
  -f enforce_admins=true \
  -f restrictions=null
```

Until this is enabled, this runbook and the PR template are the
substitute control: every change goes through a branch, a PR, and the
`quality` (and `ios-build`, for app/iOS/pubspec changes) CI jobs by
process, not by a server-side gate.

## Hard rules

- Never commit secrets, tokens, personal data, or signing material — to
  the repo or to a log pasted into a PR/commit.
- Never weaken an existing test, lint rule, or validator just to get a
  green result.
- Never claim a format/analyze/test/build result you did not actually
  produce in this session.
- Never stage or commit a file outside the current task's scope, even if
  it's already sitting modified in the working tree.
- Never invent a Jira number; descriptive names are sufficient without Jira.
