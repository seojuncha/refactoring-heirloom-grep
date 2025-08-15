# Heirloom grep Legacy Code Refactoring

Analysis and refactoring of the legacy `grep` implementation from the Heirloom Toolchest project.
Focus on code readability, maintainability, and basic bug fixes.

## Repository Structure
```
before/             # Original source snapshot
after/              # Refactored source
tests/              # Test files
do-analysis.sh      # Run clang-tidy and cppcheck
gen-test-files.sh   # Create test files to be grepped
smoke-test.sh       # Test and compare with the system grep
report.pdf          # Detailed analysis & refactoring report
```

## Build & Run
```bash
$ cd after    # or move to the 'before' for the original source
$ make        # Build
$ make test   # Run minimal smoke tests
```

To generate test files,
```bash
$ ./gen-test-files.sh
```

Run `clang-tidy` and `cppcheck`.
> Please change the `BUILD_DIR` in the script into either `after` or `before`.
```bash
$ ./do-analysis.sh
```

## Refactoring Summary
1. __Executable Separation__
* Created thin entry points: `grep_main.c`, `egrep_main.c`, and `fgrep_main.c`
* Extracted common logic into `grep_run()`
* Linked executables against a shared library (`libgrep.a`) during build

2. __Introduction of Public API__
* Added public.h exposing only the minimal declarations required by executables (`grep_run`, `progname`)
* Kept existing headers for internal implementation details

3. __Const-Qualification of Immutable Data__
* Promoted strings and option tables that do not change at runtime to const
* Improved compiler optimization opportunities and code safety

## Analysis Tools Used
* `clang-tidy` (static analysis)
* `cppcheck` (static analysis)
* `valgrind` (dynamic analysis)

## Testing
* Smoke test script: `smoke-test.sh`
* Covers: basic match, -n, -i, -v, multi-file, EOF without newline, long line handling


## Report
* `report.pdf`