# Code reviews

Review etiquette and expectations. Merge mechanics (squash-only, approval requirements, who merges) live in [CONTRIBUTING.md — Merging](../../CONTRIBUTING.md#merging); this guide covers how to be a good author and reviewer.

## Author

- **Self-review the diff before requesting review.** Anything that surprises you will surprise the reviewer more.
- Keep PRs small — aim under ~400 changed lines. Split bigger work into a sequence of PRs that each stand alone.
- The description says **why**, not just what; link the issue; fill the test plan honestly.
- Pre-annotate: leave PR comments on your own non-obvious lines (why this workaround, why this ordering) instead of making the reviewer ask.
- Respond to **every** comment before merging — with a change, an answer, or a follow-up issue. Resolving a thread means it was addressed, not dismissed.

## Reviewer

Check, roughly in order:

1. **Correctness** — does it do what the description claims? Edge cases, error paths, concurrency.
2. **Tests** — do they cover the behavior change, and would they fail if the code were wrong?
3. **Structure** — right package/module per the [structure rules](../coding-guidelines.md#code-structure); no dumping grounds; dependencies point inward.
4. **Security** — new inputs validated? authz on new resources? secrets kept out? (see [security.md](security.md))
5. **Naming and readability** — will the next reader understand this without the PR context?

Style already enforced by formatters/linters is not review material — don't comment on it.

## Comment etiquette

- Mark severity: plain comments block; prefix `nit:` for take-it-or-leave-it polish; `question:` when you're asking, not directing.
- Suggest, with reasoning — "extract this into `billing` since it's invoice logic" beats "move this".
- Questions are legitimate review output; "I don't understand this function" is a finding (the next reader won't either).
- Praise real solutions when you see them; review is not only defect hunting.

## Turnaround

- First response within **one business day** of a review request; small PRs deserve faster.
- If you can't review in time, say so and hand off — silence stalls the author.
- Author and reviewer disagree? Two rounds max in comments, then a synchronous conversation (Teams/Slack call), then the **decision lands back in the PR thread** — GitHub is the record, chat is not ([CONTRIBUTING.md](../../CONTRIBUTING.md#tech-stack)).
