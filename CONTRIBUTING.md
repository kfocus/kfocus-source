# Contribution Guidelines

## Use the Correct Base Branch
All development changes go into a default branch labeled `JJ-{YYYY}-{MM}`
which is merged and tested prior to release. Please use this as the base
branch for any Pull Request (PR).

## Quality Checks
- Ensure all code passes `shellcheck -x`. One may use shellcheck comments to
  ensure certain exceptions may allow to pass.
- If you have access to IntellJ and BashSupportPro, please ensure it passes
  there as well.
- Changes should have automated tests to ensure correctness, and updates here
  are greatly appreciated. See `test/README.md` for details on how to use or
  write.

## Code Standard
Please use the [Google Shell Style Guide][_0090] with the following refinements.

### Header
When creating a new file, use the following as a header. Notice, any
contributions will transfer copyright to MindShare Inc.

```bash
#!/bin/bash
#
# Copyright <years> MindShare Inc.
#
# Written for the Kubuntu Focus by <authors>
# <additional notes>
#
# Name     : <file-name>
# Summary  : <script use definition>
# Purpose  : <what does this do>
# Example  : <show example calls>
# License  : GPLv2
# Run By   : <what user or app calls this file>
# Spec     : <ticket #s or PRs>
#
```

We recommend you use a file like `package-main/usr/lib/kfocus/bin/kfocus-fan`
as a guideline.

## Spacing
- Indent lines two spaces per level. Do not use tabs.
- Prefer to terminate all commands with semicolons to avoid confusion.
- Limit line width to 80 characters.
- Break lines with `\` and use a continuation indent of 2 characters.
- Code in paragraph. Place an empty line after each paragraph.
- Place an empty line before and after each function.
- Remove any trailing spaces.
- No more than 2 consecutive blank lines are allowed.

### Variable names
Use `ALL_UPPER_CASE` for exported global variables. Package (file-scope)
variables are `camelCase`. Function-scope variables variables are
`snake_case`. Do not mix declaration and assignment. Current convention is to
prefix all package- and function-scope variables with an underscore to avoid
poluting the global namespace.

Use duck typing to avoid confusion. The instead of using `line` for a text
line, and `lines` as an array of lines, use `_line` and `_line_list`. Suffixes
for strings include `_str`, `_line`, `_name` etc. The suffix for arrays should
be `_list`, or for more complex lists,  `_table`. Indicate booleans with an
obvious prefix such as `_do_exit` or `_has_string` or `_is_broken`.

Functions are usually file-scoped and therefor should use the form
`_<verb><Noun>Fn`, with the `Fn` prefix identifying the variable as a
function. Declare functions without the use of the `function` keyword as shown
below.

```bash
_importCommonFn () { ... }
```

### Function Declarations
Document all functions as illustrate below. Notice the matched braches makes
it easy to bounce back and forth to the documentation.

```bash
## BEGIN _echoPkgStrFn {
# Summary   : <function use definition>
# Purpose   : <describe what this does>
# Example   : <show example calls>
# Arguments : <list arguments>
# Globals   : <list globals used here>
# Outputs   : <list stderr, stdout>
# Returns   : <specify return values or none>
#
_echoPkgStrFn () {
  # Put code here
}
# . END _echoPkgStrFn }
```

Use `declare` to create function-scope variables at the top of the function.

### Other Comments
Write and comment your code in paragraphs. Avoid comments per line or at end
of the line except in rare instances where the results are clearer. Try to
avoid noise and have the code speak for itself. Comments should be verb-noun.

```bash
# GOOD - one comment
# Skip user if not root
_user_id="$(id -u)";
if [ "${_user_id}" != '0' ]; then
  _cm2WarnStr 'User is not root. Exit';
  return 1;
fi

# BAD - too noisy
_user_id="$(id -u)"; # get user id
if [ "${_user_id}" != '0' ]; then       # check if root
  _cm2WarnStr 'User is not root. Exit'; # if so, exit.
  return 1; # non-zero return
fi # close if statement
```

## Structure
Most shell apps should have the following structure to faclitate test
development and provide consistency. Notice `set -u;` is used here. DO NOT use
`set -e`, instead trap errors.

```bash
# <HEADER>

set -u;

## BEGIN _importCommonFn {
_importCommonFn () { ... } # <= Import common.2.source
## . END _importCommonFn }

# <OTHER FUNCTION DECLARATIONS>

## BEGIN _mainFn {
_mainFn () { ... } # <= This is the main function
## . END _mainFn }

## BEGIN set global vars {
_userId="$(id -u)"; # <= Add global vars that will load for tests
## . END set global vars }

## BEGIN Run main if script is not sourced {
# <= This is only run if not sourced, like when running tests
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  _binName="$(  readlink -f "$0"       )" || exit 101;
  _binDir="$(   dirname  "${_binName}" )" || exit 101;
  _baseDir="$(  dirname  "${_binDir}"  )" || exit 101;
  _baseName="$( basename "${_binName}" )" || exit 101;
  _importCommonFn;
  _mainFn "$@";
fi
## . END Run main if script is not sourced }
```

## Common Routines
We have created common routines found in `lib/common.2.source`. Please use
these as illustrated in existing scripts. Following existing convention makes
it far easier to build solutions and create tests. All common symbols use the
`_cm2` prefix to assist in readability.

[_0090]:https://google.github.io/styleguide/shellguide.html
