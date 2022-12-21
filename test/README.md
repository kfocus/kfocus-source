# Kubuntu Focus Test Conventions

## Overview
Run `test-script/runUnitTests` to execute all tests. Run
`test-script/runUnitTests 00710` to run tests that begin with `00710`. A
single file in `test-script/unit.d` defines each test, and each test usually
has many assertions. `runUnitTests` exits with a value of 0 when all tests
pass, and non-zero when one or more fail.


## Structure
At a minimum, each test is defined by a bash source file found in
`test/test-script/unit.d/<order>_<name>`. Optionally, we place expected data
in `test-data/expect/<order>_<name>`, and initial data in
`test-data/expect/<order>_<name>`. `runUnitTests` enforces this naming
convention and provides shortcuts to use these data.

```
├── README.md   ## This file
├── test-data
│   ├── expect  ## Folders and files containing expected values for comparison
│   │   └── <directories named after unit.d test>
│   ├── initial ## Folders and files containing initial data
│   │   └── <directories named after unit.d test>
│   └── run     ## Folders and files created during test runs
│       └── <directories named after unit.d test>
└── test-script
    ├── common.2.source (symlink)
    ├── runUnitTests
    └── unit.d # Drop directory of tests
        └── <tests name like 00710_kfocusSddmSetup>
```

## Get an Existing Test
We are migrating tests from an internal repository to `test-script/unit.d`. If
you are looking for a specific test but do not see one, contact the
maintainers first to determine if one exists and can be migrated next. This
could save you significant time and trouble.

## Create Your Own Test
You can create your own test by looking at existing tests found in unit.d and
using the same convention and style. Please use the code standard found in
`CONTRIBUTING.md` to help ensure consistency and quality. Use function
declarations and aliases to create mocks.

## Future Considerations
### TAP and CI Compatible Tests
We wish to use a standard TAP compliant test framework. The obvious option
looks to be [bats-core][_0100], as it is well supported by IntelliJ and
BashSupportPro. Version 1.8.2 is currently [bundled with that IDE][_0105]. The
documentation [is here][_0107]. Key capabilities we want include IDE
compatibility, CI compatibility (TAP preferred), auto-discovery of new tests,
parallel execution, before-after functions, before-after-all functions, tests
written in bash, and good documentation.

If bats-core doesn't work for some reason, there are other [frameworks
available][_0110]. One can look at test-drives for [bash_unit][_0120],
[shellspec][_0130], and others at the above overview.

### CI Integration
We wish to trigger some or all tests as CI jobs.

### Commit Hook
We wish to add a commit hook to run shellcheck on all changed files, and to
automatically run some or all unit tests.

## END

[_0100]:https://github.com/bats-core/bats-core
[_0105]:https://www.bashsupport.com/news/bashsupport-pro-3.0/?source=plugin#bats-core-support
[_0107]:https://bats-core.readthedocs.io/en/stable/
[_0110]:https://github.com/dodie/testing-in-bash
[_0120]:https://github.com/pgrange/bash_unit
[_0130]:https://github.com/shellspec/shellspec

