# Contribution Guidelines

## Use the Correct Base Branch
All development changes go into a default branch labeled `JJ-{YYYY}-{MM}`
which is merged and tested prior to release. Please use this as the base
branch for any Pull Requests (PR).

## Quality Checks
- Ensure all code passes `shellcheck -x`. Use shellcheck comments to
  allow approved exceptions to pass like so: `# shellcheck disable=SC2091`
- If you have access to them, use IntelliJ IDEA (Community Edition or
  Ultimate) with the paid BashSupportPro plugin. Fix all errors and warnings
  caught by the linter. Use bashsupport comments to allow approved exceptions
  to pass like so: `# bashsupport disable=BP2001`
- Changes should have automated tests to ensure correctness. See
  `test/README.md` for details on how to write and use tests.

## Copyright and Licensing
All original contributions must have copyright transferred to MindShare Inc,
and must be licensed under the GNU General Public License, version 2.
Third-party content may be added so long as it is open-source and does not
introduce licesning conflicts.

To ensure these requirements are met, we use standard copyright headers on
most of our files. See CODING\_GUIDELINES.md for more information.

## Code Standard
See CODING\_GUIDELINES.md
