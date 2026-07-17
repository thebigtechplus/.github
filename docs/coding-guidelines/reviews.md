# Code reviews

Review etiquette and expectations. Review is the highest-leverage hour in engineering: it catches bugs while they are cheap, spreads system knowledge so no file has a single owner, and is where junior engineers actually learn the craft. Merge mechanics (squash-only, approval requirements, who merges) live in [CONTRIBUTING.md — Merging](../../CONTRIBUTING.md#merging); this guide covers how to be a good author and reviewer.

## Author

- **Self-review the diff before requesting review.** You will catch the debug print, the leftover TODO, and the file that should not be there — each one you ship to a reviewer costs a full round trip and teaches them to skim your next PR. Anything that surprises you will surprise the reviewer more.
- Keep PRs small — aim under ~400 changed lines. Defect-detection rates fall off a cliff as diffs grow: a reviewer who can hold the whole change in their head finds real bugs; past a certain size every review silently degrades into "looks good to me". Split bigger work into a sequence of PRs that each stand alone.
- The description says **why**, not just what — the diff already shows what changed; only you know what it was *for*, and the reviewer judges correctness against intent. Link the issue; fill the test plan honestly (a false "tests pass" burns exactly once, and then every claim you make gets re-verified).
- Pre-annotate: leave PR comments on your own non-obvious lines (why this workaround, why this ordering) instead of making the reviewer ask — you answer the question once, before it stalls the review a day.
- Respond to **every** comment before merging — with a change, an answer, or a follow-up issue. Resolving a thread means it was addressed, not dismissed; silently resolved comments teach reviewers their time is wasted, and they stop spending it.

## Reviewer

Check, roughly in order — ordered by cost of missing it:

1. **Correctness** — does it do what the description claims? Edge cases, error paths, concurrency. A missed bug ships to users; everything else on this list is cheaper to fix later.
2. **Tests** — do they cover the behavior change, and would they fail if the code were wrong? A test that cannot fail is documentation of nothing.
3. **Structure** — right package/module per the [structure rules](../coding-guidelines.md#code-structure); no dumping grounds; dependencies point inward. Structure is nearly free to fix now and prohibitively expensive after ten features are built on top of it.
4. **Security** — new inputs validated? authz on new resources? secrets kept out? (see [security.md](security.md)) — reviews are the last human eyes before an IDOR or a leaked key reaches production.
5. **Naming and readability** — will the next reader understand this without the PR context? You, right now, are the only person who will ever read this code *with* the explanation attached.

Style already enforced by formatters/linters is not review material — don't comment on it; the machine already won that argument, and style nits crowd out the correctness findings only a human can make.

## Comment etiquette

- Mark severity: plain comments block; prefix `nit:` for take-it-or-leave-it polish; `question:` when you're asking, not directing — unlabeled comments force the author to guess what actually gates the merge, and guessing wrong wastes a round trip either way.
- Suggest, with reasoning — "extract this into `billing` since it's invoice logic" beats "move this": the reasoning is what the author reuses on the next PR, so review without it fixes one PR instead of a habit.
- Questions are legitimate review output; "I don't understand this function" is a finding — the next reader won't understand it either, and they won't have the author on hand to explain.
- Praise real solutions when you see them — review that only ever criticizes trains authors to dread it and hide from it; naming what was done well also spreads the technique to everyone reading the thread.

## Turnaround

- First response within **one business day** of a review request; small PRs deserve faster — a stalled review blocks the author's next task, and the context they will need for your comments decays by the hour.
- If you can't review in time, say so and hand off — silence stalls the author; a fast "not me, ask X" costs ten seconds and saves a day.
- Author and reviewer disagree? Two rounds max in comments, then a synchronous conversation (Teams/Slack call), then the **decision lands back in the PR thread** — text disagreements harden positions that a five-minute call dissolves, but GitHub is the record and chat is not ([CONTRIBUTING.md](../../CONTRIBUTING.md#tech-stack)): a decision that lives only in a call is invisible to the next person who asks "why is it like this?".
