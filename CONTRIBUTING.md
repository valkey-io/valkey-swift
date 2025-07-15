# Contributing to Valkey Swift

Thanks for your interest in contributing to Valkey Swift — the Swift client library for Valkey!
We appreciate all contributions — whether it’s fixing bugs, improving documentation, or adding features.

## Legal
By submitting a pull request, you represent that you have the right to license your contribution to the community, and agree by submitting the patch
that your contributions are licensed under the Apache 2.0 license (see [LICENSE](LICENSE)).

## Developer Certificate of Origin

We respect the intellectual property rights of others and we want to make sure
all incoming contributions are correctly attributed and licensed. A Developer
Certificate of Origin (DCO) is a lightweight mechanism to do that. The DCO is
a declaration attached to every commit. In the commit message of the contribution,
the developer simply adds a `Signed-off-by` statement and thereby agrees to the DCO,
which you can find at [DeveloperCertificate.org](http://developercertificate.org/).

We require that every contribution to Valkey Swift to be signed with a DCO. We require the
usage of known identity (such as a real or preferred name). We do not accept anonymous
contributors nor those utilizing pseudonyms. A DCO signed commit will contain a line like:

```text
Signed-off-by: Jane Smith <jane.smith@email.com>
```

You may type this line on your own when writing your commit messages. However, if your
user.name and user.email are set in your git configs, you can use `git commit` with `-s`
or `--signoff` to add the `Signed-off-by` line to the end of the commit message. We also
require revert commits to include a DCO.

If you're contributing code to the Valkey Swift project in any other form, including
sending a code fragment or patch via private email or public discussion groups,
you need to ensure that the contribution is in accordance with the DCO.

## Contributor Conduct
All contributors are expected to adhere to the project's [Code of Conduct](CODE_OF_CONDUCT.md).

## Submitting a bug or issue

Please ensure to include the following in your bug report
- A concise description of the issue, what happened and what you expected.
- Simple reproduction steps
- Version of the library you are using
- Contextual information (Swift version, OS version, Valkey version, etc)

## Submitting a Pull Request

Please ensure to include the following in your Pull Request
- A description of what you are trying to do. What the PR provides to the library, additional functionality, fixing a bug etc
- A description of the code changes
- Documentation on how these changes are being tested
- Additional tests to show your code working and to ensure future changes don't break your code.

Please keep your PRs to a minimal number of changes. If a PR is large try to split it up into smaller PRs. Don't move code around unnecessarily it makes comparing old with new very hard.

The main development branch of the repository is  `main`.

## Formatting

We use [Apple's swift-format](https://github.com/swiftlang/swift-format) for formatting code. PRs will not be accepted if they haven't be formatted.