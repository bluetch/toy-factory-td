---
name: feedback_no_push
description: Never push to git unless the user explicitly requests it
type: feedback
---

Do NOT run `git push` unless the user explicitly says to push.

**Why:** User stated clearly "請不要push 我說過除非我說要push" — they want full control over when code is pushed to the remote.

**How to apply:** After committing locally, stop there. Never push as part of a workflow unless the user says "push" or "幫我 push" in that message.
