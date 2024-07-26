# OMS Contributing Guide

Hi! I'm really excited that you are interested in contributing to OMS. Before submitting your contribution, please make sure to take a moment and read through the following guidelines:

## Contributing
When contributing to this repository, please first discuss the change you wish to make via issue, email, or any other method with the owners of this repository before making a change.



## Pull Request Guidelines

### What kinds of Pull Requests are accepted?

- Bug fix that addresses a clearly identified bug. **"Clearly identified bug"** means the bug has a proper reproduction either from a related open issue, or is included in the PR itself. Avoid submitting PRs that claim to fix something but do not sufficiently explain what is being fixed.

- New feature that addresses a clearly explained and widely applicable use case. **"Widely applicable"** means the new feature should provide non-trivial improvements to the majority of the user base. Vue already has a large API surface so we are quite cautious about adding new features - if the use case is niche and can be addressed via userland implementations, it likely isn't suitable to go into core.

  The feature implementation should also consider the trade-off between the added complexity vs. the benefits gained. For example, if a small feature requires significant changes that spreads across the codebase, it is likely not worth it, or the approach should be reconsidered.

  If the feature has a non-trivial API surface addition, or significantly affects the way a common use case is approached by the users, it should go through a discussion first in the [RFC repo](https://github.com/vuejs/rfcs/discussions). PRs of such features without prior discussion make it really difficult to steer / adjust the API design due to coupling with concrete implementations, and can lead to wasted work.

- Chore: typos, comment improvements, build config, CI config, etc. For typos and comment changes, try to combine multiple of them into a single PR.

- **It should be noted that we discourage contributors from submitting code refactors that are largely stylistic.** Code refactors are only accepted if it improves performance, or comes with sufficient explanations on why it objectively improves the code quality (e.g. makes a related feature implementation easier).

  The reason is that code readability is subjective. The maintainers of this project have chosen to write the code in its current style based on our preferences, and we do not want to spend time explaining our stylistic preferences. Contributors should just respect the established conventions when contributing code.

  Another aspect of it is that large scale stylistic changes result in massive diffs that touch multiple files, adding noise to the git history and makes tracing behavior changes across commits more cumbersome.

- If adding a new feature:

  - Add accompanying test case.
  - Provide a convincing reason to add this feature. Ideally, you should open a suggestion issue first and have it approved before working on it.

- If fixing a bug:

  - If you are resolving a special issue, add `(fix #xxxx[,#xxxx])` (#xxxx is the issue id) in your PR title for a better release log, e.g. `update entities encoding/decoding (fix #3899)`.
  - Provide a detailed description of the bug in the PR. Live demo preferred.
  - Add appropriate test coverage if applicable. You can check the coverage of your code addition by running `nr test-coverage`.
