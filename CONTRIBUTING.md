# OMS Contributing Guide

Hi! I'm really excited that you are interested in contributing to OMS. Before submitting your contribution, please make sure to take a moment and read through the following guidelines:

## Table of Contents
1. [Code of Conduct](#code-of-conduct)
2. [How Can I Contribute?](#how-can-i-contribute)
    - [Reporting Bugs](#reporting-bugs)
    - [Feature Requests](#feature-requests)
    - [Submitting Changes](#submitting-changes)
3. [Development Guidelines](#development-guidelines)
    - [Coding Standards](#coding-standards)
    - [Commit Messages](#commit-messages)
    - [Pull Request Process](#pull-request-process)
4. [Documentation](#documentation)
5. [License](#license)

## Code of Conduct
Please note that this project is governed by a [Code of Conduct](CodeofConduct.md). By participating, you agree to uphold this code. Please report any unacceptable behavior to [rojuadeyemi@yahoo.com](mailto:rojuadeyemi@yahoo.com).

## How Can I Contribute?

### Reporting Bugs
- Ensure the bug has not already been reported by searching the [issue tracker](./issues).
- If you're unable to find an open issue, create a new one.
- Use a clear and descriptive title for the issue.
- Provide as much detail as possible, including steps to reproduce the issue, the expected outcome, and the actual outcome.

### Feature Requests
- Check if the feature has already been requested by searching the [issue tracker](./issues).
- If it hasn't, create a new issue.
- Describe the feature in detail, including its purpose and how it can improve the project.

### Submitting Changes
- Fork the repository and create a new branch for your changes (`git checkout -b feature/your-feature-name`).
- Ensure your code adheres to the project's coding standards.
- Commit your changes with a clear and descriptive message.
- Push your branch to your forked repository.
- Submit a pull request, describing your changes and linking to any relevant issues.

## Development Guidelines

### Coding Standards
- Write clear, concise, and well-documented queries.

### Commit Messages
- Use the [Conventional Commits](https://www.conventionalcommits.org/) format.
- Example: `fix: correct typo in documentation`

### Pull Request Process
1. Ensure your changes do not break existing functionality.
2. Add or update tests to cover your changes.
3. Submit your pull request for review.

## Documentation
- Update the documentation as needed, especially if you're introducing new features or changes.
- Ensure that the documentation is clear and easy to understand.

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
 
## License
By contributing, you agree that your contributions will be licensed under the same license as the project's license.
