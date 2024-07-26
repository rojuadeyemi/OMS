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

- If adding a new feature:

  - Add accompanying test case.
  - Provide a convincing reason to add this feature. Ideally, you should open a suggestion issue first and have it approved before working on it.

- If fixing a bug:

  - If you are resolving a special issue, add `(fix #xxxx[,#xxxx])` (#xxxx is the issue id) in your PR title for a better release log, e.g. `update entities encoding/decoding (fix #3899)`.
  - Provide a detailed description of the bug in the PR. Live demo preferred.
  - Add appropriate test coverage if applicable. You can check the coverage of your code addition by running `nr test-coverage`.

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
 
## License
By contributing, you agree that your contributions will be licensed under the same license as the project's license.
