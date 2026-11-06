---
name: skill-pr-feedback
description: >
  Handles the review comments the user left on one of their own Sport Timer pull requests. The user and the
  conductor discuss each comment in chat as usual, fixes are made, the fix diff is reviewed by agent-pr-review,
  and then the skill commits, pushes the PR branch and posts a very short status reply in each comment thread
  (fixed, answered or not changed). Use when the user says "check the PR comments", "I left comments on the PR",
  "answer the review", or gives a PR number, URL or review link of their own PR. Only for this repo. Not for
  reviewing someone else's PR.
argument-hint: "[PR number, PR URL or review link]"
model: claude-sonnet-5-5
effort: medium
---

# PR feedback

You work through the review comments the user left on their own PR. The user discusses each comment with you in chat. When they say they are done, you review the fixes, commit, push and post a short status reply in each thread.

## Standing authorization

The user starts this skill on purpose, and while it runs, in this repo only, it may do what the global working rules normally forbid:

- Commit the fixes and push the PR branch (a plain `git push`).
- Post one short reply in each inline review thread, and nothing else, on the PR it works on.
- Check out the PR's head branch when it is not the current one.

Limits that always hold: never push to `master` or `main`, never force-push, never merge, never create a new branch, never resolve or minimize a thread, never edit or delete a comment, never post a PR review or a new PR comment of its own, never reply to a comment that is not part of the discussion. The commit follows `.agents/rules/git-commits.md`, including its `Co-Authored-By` line: in this repo that project rule wins over the global rule that forbids the line. Check `git config user.email` before the commit. If it is not the repo-local noreply address (`40612984+alexaniko88@users.noreply.github.com`), set it with `git config user.email` first. Never use a company address.

## Step 1: Find the PR and the comments

- Take the PR from the argument. With no argument, use `gh pr view --json number,headRefName,state,url` for the current branch. If the PR is not open, stop and tell the user.
- Get `<owner>/<repo>` from `gh repo view --json nameWithOwner`. Never hardcode it.
- Check the current branch is the PR's `headRefName`. If not, check it out, then `git pull --ff-only`. Uncommitted changes from the current discussion are expected and stay; stop and ask only when they look unrelated to the PR.
- Read the comments with GET calls only:
  ```bash
  gh api repos/<owner>/<repo>/pulls/<n>/comments --paginate   # inline review comments
  gh api repos/<owner>/<repo>/issues/<n>/comments --paginate  # general comments
  ```
  A review link (`#pullrequestreview-<id>`) limits the list to `pulls/<n>/reviews/<id>/comments`. Only the comments of the PR author count. Group replies under their root comment and skip comments that already have a reply from this skill (they start with "Fixed in", "Answered:" or "Not changed:").

## Step 2: Discuss one comment at a time

For each comment, show the file, line, author and body as written. Read the file as it is now, because the stored hunk can be old. Say in one or two lines what it asks. Then:

- If it is a question, answer it in chat and say whether a code change is worth it.
- If it is a change request, give the concrete fix (before and after code, in a fenced block) and wait for the user's choice.
- If it is a judgment call, ask the user with 2 to 4 options, recommended first (use a question tool when the tool has one).

Apply the approved fix with a general-purpose agent that starts with "Read `.agents/skills/skill-orchestrator/roles/agent-implementer.md` and follow it" and has `model` and `effort` set from that role file. The brief has the repo path, branch, the comment, the approved fix and "do not commit, stage or push". Do not move to the next comment until the user says so.

Keep a status list while you go: for each comment its id, and one of `fixed`, `answered` (no code change) or `not changed` (with the reason, one line).

If a fix changes a rule the code or the rule files describe, update the rule file in the same change (never `docs/CodeStyleGuide.md`).

## Step 3: When the user says they are done

Do these in order, with no more questions. When no comment needed a code change (every status is `answered` or `not changed`), there is nothing to check, review or commit: skip to step 5 and post the replies without a commit hash.

1. **Checks.** Run `fvm dart tool/agent_check.dart`. It picks the format, analyze, tests and snapshots the changed files need. A UI change that alters a captured screen refreshes the goldens as `CLAUDE.md` describes. Fix failures. If it still fails after two tries, stop and show the output.
2. **Review.** Start a general-purpose agent with "Read `.agents/skills/skill-orchestrator/roles/agent-pr-review.md` and follow it", with `model` and `effort` from that role file. Give it the fix diff (`git diff HEAD`, plus untracked files) and the same project overrides that `skill-orchestrator` Stage 4 gives (layer rules, l10n keys, extensions, Styling and theme). When the diff has no `lib/` files, tell it to review every changed file. Fix Critical and General findings with the implementer role and re-run the checks. At most 2 rounds. If Critical or General findings remain, stop, show them and do not commit.
3. **Commit.** Run `git status -sb` and `git config user.email`. Stage only the files of these fixes (never `git add -A`). Scan the staged diff for local absolute paths, team IDs, keys and tokens. Make one commit for all the fixes, in the format of `.agents/rules/git-commits.md`, with the `Co-Authored-By` line the rule asks for. Use the type that matches the change (`refactor`, `fix`, `chore`, ...); never `improve`.
4. **Push.** `git push` the PR branch. If it is rejected, do not force: stop and tell the user.
5. **Reply.** Post one reply per inline comment (see below), with the short commit hash in the `Fixed in` ones. Post them only after the push worked.
6. **Report** in chat: the commit hash and message, the files, the check and review results, the replies posted with their links, and every `FIXME-ALEX`, `TODO` or `FIXME` added on the branch with `file:line`.

## The replies

One reply in each thread, 1 or 2 plain sentences, written as a teammate, with no filler ("Great catch!") and no blockquote:

- `Fixed in <sha>: <what changed, one line>.`
- `Answered: <the answer, one line>. No code change.`
- `Not changed: <the reason, one line>.`

Write the text to a file in the scratchpad first, because an apostrophe breaks an inline quote, then post it:

```bash
gh api repos/<owner>/<repo>/pulls/<n>/comments/<root_comment_id>/replies -F body=@<file>
```

Reply to the root comment of the thread, never to a reply in it. General PR comments (not inline) get no reply from the skill: list them in the chat report with a draft reply, so the user posts them. Show every reply in chat in the report, in plain text so the user can copy them. Do not resolve the threads: the user or the reviewer does that after checking the fix.

## Anything else

- Mention an unrelated issue you saw in one line at the end, without acting on it.
- Write all narrative in plain, simple English.
