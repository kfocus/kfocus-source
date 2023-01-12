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

### Spacing
- Indent lines two spaces per level. Do not use tabs.
- Prefer to terminate all commands with semicolons to avoid confusion.
- Limit line width to 80 characters.
- Break lines with `\` and use a continuation indent of 2 characters.
- Code in paragraphs. Place an empty line after each paragraph.
- Place an empty line before and after each function.
- Remove any trailing spaces.
- Do not use more than 2 consecutive blank lines between sections.

### Variable Declaration and Assignment
Declare all function-scope variables at the top of a function using a single
`declare` statement. Do not combine declaration and assignment. Instead, assign
an initial value to a variable as needed before first use.

Use `ALL_UPPER_CASE` names for exported global variables. Use `camelCase` for
package (file-scope) variables. Use `snake_case` for function-scope (local)
variables. Prefix package- and function-scope variables with an underscore to
avoid conflicting with other variables in the bash environment.

Use duck typing to avoid confusion. Instead of using `line` for a text line
and `lines` as an array of lines, use `_line` and `_line_list`. Use obvious
suffixes for strings such as `_str`, `_line`, or `_name`. Use the `_list`
suffix for simple arrays and `_table` for delimited lists. Use an `_int`, `_idx`,
or `_count` suffix to indicate an integer. Use the `_num` suffix to indicate
a number. Prefix booleans with sensibly such as `_do_exit`, `_has_string`,
or `_is_empty`.

### Function Declarations
Please use the template below for function declarations. Function are usually
package-scoped, and therefore should usually be name like `_<verb><Noun>Fn`,
with the `Fn` suffix identifying the variable as a function. The matched
braces make it easy to quickly move the cursor to the beginning or end of
the function with many editors.

```bash
## BEGIN _verbNounFn {
# Summary   : <function use definition>
# Purpose   : <describe what this does>
# Example   : <show example calls>
# Arguments : <list arguments>
# Globals   : <list globals used here>
# Outputs   : <list stderr, stdout>
# Returns   : <specify return values or none>
#
_verbNounFn () {
  # Put code here
}
# . END _verbNounFn }
```

### Comments
Write and comment your code in paragraphs. Avoid comments per line or at the
end of lines except in rare instances where the results are clearer. Try to
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
_user_id="$(id -u)"; # user id get
if [ "${_user_id}" != '0' ]; then       # root check
  _cm2WarnStr 'User is not root. Exit'; # exit if not root
  return 1; # non-zero return
fi # close if statement
```

## Structure
Most shell apps should have the following structure to facilitate test
development and provide consistency. Notice `set -u;` is used here. DO NOT use
`set -e`; trap errors instead.

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

When in doubt, terminate commands with a semicolon.

## Common Routines
We have created common routines found in `lib/common.2.source`. Please use
these as illustrated in existing scripts. Following existing convention makes
it far easier to build solutions and create tests. All common symbols use the
`_cm2` prefix to assist in readability.

[_0090]:https://google.github.io/styleguide/shellguide.html
