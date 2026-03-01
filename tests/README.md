# showlinenum.awk Test Suite

This directory contains unit tests for the `showlinenum.awk` script.

## Test Structure

```
tests/
├── inputs/         # Test input files (.diff files)
├── outputs/        # Expected output files (.out files)
├── run_tests.sh    # Test runner script
└── README.md       # This file
```

### File Naming Convention

Each test consists of:

- `XXX_test_name.diff` - Input diff file in `inputs/`
- `XXX_test_name.out` - Expected output in `outputs/`
- `XXX_test_name.args` - (Optional) Command-line arguments in `inputs/`
- `XXX_test_name.error` - (Optional) Expected error pattern in `outputs/` for failure tests

Where `XXX` is a three-digit test number (001, 002, etc.).

## Running Tests

Run all tests:

```bash
./run_tests.sh
```

Run a specific test:

```bash
./run_tests.sh 001    # Runs test 001
./run_tests.sh 003    # Runs test 003
```

## Test Cases

| #   | Name                     | Description                                                                                                                                                                                          | Options                                                                 |
| --- | ------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| 1   | Basic Additions          | Tests basic diff output with added lines. Verifies that line numbers are correctly added and that the `+` indicator is preserved.                                                                    | Default (show_header=1)                                                 |
| 2   | Deletions                | Tests diff output with deleted lines. Verifies that deleted lines show padding instead of line numbers and preserve the `-` indicator.                                                               | Default                                                                 |
| 3   | Show Path                | Tests the `show_path=1` option which prepends file paths to each line number.                                                                                                                        | `show_path=1 show_header=0`                                             |
| 4   | Hide Hunk Headers        | Tests the `show_hunk=0` option which hides the `@@ ... @@` hunk headers while keeping other headers.                                                                                                 | `show_hunk=0`                                                           |
| 5   | Removed File             | Tests handling of a completely removed file. All lines should show `~` as the line number indicator with the old file path.                                                                          | Default                                                                 |
| 6   | Binary File (Hidden)     | Tests default behavior for binary files. When `show_header=1` and `show_binary` is not explicitly set, binary file changes are shown in headers only.                                                | Default                                                                 |
| 7   | Binary File (Shown)      | Tests `show_binary=1` option which shows an empty format line (`:` only) for binary files that differ.                                                                                               | `show_binary=1`                                                         |
| 8   | Binary File Removed      | Tests handling of removed binary files. Shows `~:` to indicate a removed binary file.                                                                                                                | `show_binary=1`                                                         |
| 9   | No Newline at EOF        | Tests the handling of the `\ No newline at end of file` warning. The warning line should have padding instead of a line number.                                                                      | Default                                                                 |
| 10  | Multiple Files           | Tests processing multiple files in a single diff output. Each file should be handled independently with correct line numbering.                                                                      | Default                                                                 |
| 11  | Large Line Numbers       | Tests that large line numbers (9,999,998+) are displayed correctly without scientific notation.                                                                                                      | Default                                                                 |
| 12  | Multiple Hunks           | Tests a file with multiple separate hunks. Line numbers should reset appropriately for each hunk.                                                                                                    | Default                                                                 |
| 13  | New File                 | Tests handling of a newly added file. All lines should be marked with `+` indicator.                                                                                                                 | Default                                                                 |
| 14  | Path with Spaces         | Tests handling of file paths containing spaces. The path should be correctly extracted and displayed.                                                                                                | `show_path=1 show_header=0`                                             |
| 15  | Colon in Path            | Tests handling of paths with colons (e.g., `HEAD:file.txt`) when `allow_colons_in_path=1` is set.                                                                                                    | `show_path=1 allow_colons_in_path=1 show_header=0`                      |
| 16  | Mnemonic Diff Format     | Tests handling of mnemonic diff format which uses `i/` and `w/` prefixes instead of `a/` and `b/`. Generated by `git diff --no-index` or with `diff.mnemonicPrefix=true`.                            | Default                                                                 |
| 17  | Deletion at Boundary     | Tests line number formatting when a deletion occurs at the transition from 2-digit to 3-digit line numbers (at line 100). Verifies correct alignment.                                                | Default                                                                 |
| 18  | Deletion at 99           | Tests line number formatting around line 99-100 boundary with context lines after the deletion.                                                                                                      | Default                                                                 |
| 19  | Color Line Numbers       | Tests ANSI color output for line numbers using the `color_line_number` option. Verifies that line numbers are colored (ANSI code 32 for green).                                                      | `color_line_number=32`                                                  |
| 20  | Color Path               | Tests ANSI color output for file paths using the `color_path` option. Verifies that paths are colored (ANSI code 34 for blue) when `show_path=1` is enabled.                                         | `show_path=1 color_path=34`                                             |
| 21  | Color Separator          | Tests ANSI color output for the separator (colon) between line number and content using the `color_separator` option. Verifies separators are colored (ANSI code 36 for cyan).                       | `color_separator=36`                                                    |
| 22  | Color Combined           | Tests combining multiple color options simultaneously. Line numbers use bold green (1;32), paths use bold blue (1;34), and separators use yellow (33).                                               | `show_path=1 color_line_number=1;32 color_path=1;34 color_separator=33` |
| 23  | Colored Input            | Tests handling of ANSI color codes in input diff (from `git diff --color=always`). Verifies that color codes are properly preserved in the output while being correctly parsed during processing.    | Default                                                                 |
| 24  | c/ Prefix                | Tests handling of `c/` prefix in diff headers (commit prefix).                                                                                                                                       | Default                                                                 |
| 25  | o/ Prefix                | Tests handling of `o/` prefix in diff headers (object prefix).                                                                                                                                       | Default                                                                 |
| 26  | Quoted Paths             | Tests handling of quoted file paths (paths with special characters that git quotes with double quotes).                                                                                              | Default                                                                 |
| 27  | Single Line Hunk         | Tests handling of a hunk with only one line where the line count is not explicitly specified in the hunk header (`@@ -1 +1 @@`).                                                                     | Default                                                                 |
| 28  | Binary with Spaces       | Tests handling of binary files whose paths contain spaces.                                                                                                                                           | `show_binary=1`                                                         |
| 29  | Large Context            | Tests handling of diffs with large sections of unchanged context lines surrounding a small change.                                                                                                   | Default                                                                 |
| 30  | Hunks with Gaps          | Tests a file with multiple hunks separated by large gaps, verifying that line numbers and formatting are correct across distant hunks.                                                               | Default                                                                 |
| 31  | Binary File Added        | Tests handling of a newly added binary file. Shows empty format line for new binary files.                                                                                                           | `show_binary=1 show_path=1`                                             |
| 32  | Header Off Hunk On       | Tests the unusual combination of `show_header=0` with `show_hunk=1` to verify hunk headers display correctly without file headers.                                                                   | `show_header=0 show_hunk=1`                                             |
| 33  | Minimal Output           | Tests minimal output mode with both headers and paths disabled (`show_header=0 show_path=0`), showing only line numbers and diff indicators.                                                         | `show_header=0 show_path=0`                                             |
| 34  | Empty Hunk               | Tests handling of empty hunks (`@@ -10,0 +11,0 @@`) with zero lines changed, verifying correct parsing and output.                                                                                   | Default                                                                 |
| 35  | Renamed File             | Tests handling of renamed files with similarity index and rename from/to headers. Verifies the script gracefully handles rename metadata.                                                            | Default                                                                 |
| 36  | Mode Change Only         | Tests diffs with only file mode changes (e.g., chmod) and no content changes. No hunks follow the header.                                                                                            | Default                                                                 |
| 37  | Hunk at Line Zero        | Tests hunks starting at line 0 (`@@ -0,0 +1,3 @@`), typically seen when adding lines at the beginning of a file.                                                                                     | Default                                                                 |
| 38  | Context Only Hunk        | Tests hunks containing only unchanged context lines (all lines start with space), verifying all lines increment correctly.                                                                           | Default                                                                 |
| 39  | Extreme Line Numbers     | Tests handling of extremely large line numbers near AWK's floating point limit (9,007,199,254,740,992) to verify no scientific notation is used.                                                     | Default                                                                 |
| 40  | Path with Tab            | Tests handling of file paths containing tab characters, which git quotes with double quotes.                                                                                                         | Default                                                                 |
| 41  | Mixed File Types         | Tests a single diff containing multiple file types: new file, modified binary, removed file, and modified text file. Verifies state resets correctly between files.                                  | Default                                                                 |
| 42  | No-Prefix Basic          | Tests basic `--no-prefix` format with additions. Verifies paths without `a/` and `b/` prefixes are correctly parsed.                                                                                 | Default                                                                 |
| 43  | No-Prefix Deletions      | Tests `--no-prefix` format with deleted lines. Verifies line number padding works correctly without path prefixes.                                                                                   | Default                                                                 |
| 44  | No-Prefix New File       | Tests `--no-prefix` format with a newly added file. Verifies all lines are marked with `+` indicator and paths are extracted correctly.                                                              | Default                                                                 |
| 45  | No-Prefix Removed File   | Tests `--no-prefix` format with a deleted file. All lines should show `~` as the line number indicator.                                                                                              | Default                                                                 |
| 46  | No-Prefix Spaces         | Tests `--no-prefix` format with file paths containing spaces (unquoted). Verifies path extraction and display with `show_path=1`.                                                                    | `show_path=1 show_header=0`                                             |
| 47  | No-Prefix Binary         | Tests `--no-prefix` format with binary files. Verifies binary files are handled correctly without path prefixes.                                                                                     | `show_binary=1 show_path=1`                                             |
| 48  | No-Prefix Multiple Files | Tests `--no-prefix` format with multiple files in a single diff. Verifies each file is handled independently with correct line numbering.                                                            | Default                                                                 |
| 49  | No-Prefix Quoted Spaces  | Tests `--no-prefix` format with quoted file paths containing spaces. Verifies quoted paths without prefixes are correctly parsed.                                                                    | Default                                                                 |
| 50  | No-Prefix Binary Removed | Tests `--no-prefix` format with a removed binary file. Shows `~:` to indicate a removed binary file without path prefix.                                                                             | `show_binary=1 show_path=1`                                             |
| 51  | No Newline Removed       | Tests handling of "No newline at end of file" warning when the old file is missing the newline but the new file has it (warning after `-` line). Complements test 09 which covers the opposite case. | Default                                                                 |
| 52  | Header and Path          | Tests the non-default combination of both `show_header=1` and `show_path=1` enabled simultaneously. Verifies that both file headers and path prefixes display correctly together.                    | `show_header=1 show_path=1`                                             |
| 53  | Color Line and Separator | Tests combining `color_line_number` and `color_separator` options together without path coloring. Verifies partial color combinations work correctly.                                                | `color_line_number=32 color_separator=36`                               |
| 54  | Color Path and Separator | Tests combining `color_path` and `color_separator` options without line number coloring. Verifies path and separator colors work together.                                                           | `show_path=1 show_header=0 color_path=34 color_separator=36`            |
| 55  | Color Line and Path      | Tests combining `color_line_number` and `color_path` options without separator coloring. Verifies line number and path colors work together.                                                         | `show_path=1 show_header=0 color_line_number=32 color_path=34`          |
| 56  | Binary Off               | Tests explicit `show_binary=0` option to ensure binary file diffs are hidden when disabled, even when default behavior would show them.                                                              | `show_binary=0`                                                         |
| 57  | No Colons No Path        | Tests `allow_colons_in_path=0` when `show_path=0` to verify the option works correctly when paths aren't displayed.                                                                                  | `allow_colons_in_path=0 show_path=0`                                    |
| 58  | Empty Input              | Tests handling of completely empty input with no diff content. Verifies script gracefully handles empty input without errors.                                                                        | Default                                                                 |
| 59  | Headers Only Index       | Tests diff with only header lines (diff/index) but no path or hunk information. Verifies headers-only diffs are handled correctly.                                                                   | Default                                                                 |
| 60  | Extreme Lines Color      | Tests extremely large line numbers (near AWK's floating point limit) combined with color output. Verifies no scientific notation appears in colored output.                                          | `color_line_number=1;32 color_separator=36`                             |
| 61  | No-Prefix Color          | Tests `--no-prefix` format combined with color options. Verifies that path coloring, line number coloring, and separator coloring work correctly without path prefixes.                              | `show_path=1 show_header=0 color_line_number=32 color_path=34 color_separator=36` |
| 62  | Trailing Tab             | Tests handling of paths with trailing tabs in the extracted path data. Verifies the script correctly removes erroneous trailing tabs that git diff may add.                                          | Default                                                                 |
| 63  | Mixed Prefixes           | Tests handling of multiple files with different prefix types (a/b, i/w, c/o) in a single diff output. Verifies each prefix type is correctly processed.                                              | Default                                                                 |
| 64  | Unicode Path             | Tests handling of file paths containing Unicode characters (e.g., Chinese and Japanese characters). Verifies non-ASCII characters in paths are processed correctly.                                  | `show_path=1 show_header=0`                                             |
| 65  | Long Path                | Tests handling of very long file paths (>256 characters). Verifies the script can handle paths longer than typical filesystem limits without truncation or errors.                                   | Default                                                                 |
| 66  | Empty File               | Tests adding content to a completely empty file (0 lines → N lines). Verifies hunks starting at `@@ -0,0 +1,N @@` are handled correctly.                                                             | Default                                                                 |

## Error Test Cases

Error tests are identified by `.error` files in the `outputs/` directory containing the expected error pattern. The test runner expects the script to fail and verifies the error message contains the specified pattern.

| #   | Name                         | Description                                                                                                                                              | Options                 | Expected Error                                              |
| --- | ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------- | ----------------------------------------------------------- |
| 90  | Combined Diff Format Error   | Tests that combined diff format (used in merge commits with multiple parents) is properly rejected with an appropriate error message.                    | Default                 | "Combined diff format not supported"                        |
| 91  | Missing Path Info Error      | Tests that a malformed diff missing the `---` and `+++` path lines is detected and rejected.                                                             | Default                 | "Line info found before path info"                          |
| 92  | Colon in Path Error          | Tests that paths containing colons are rejected by default when `show_path=1` (to preserve parsing compatibility).                                       | `show_path=1`           | "colons in path are forbidden"                              |
| 93  | Invalid Color Parameter      | Tests that non-numeric color parameters are rejected with an appropriate error.                                                                          | `color_line_number=red` | "color parameters may contain only numbers and semi-colons" |
| 94  | Bad Diff Indicator           | Tests that diff lines with invalid indicators (not space, +, -, or \) are properly rejected.                                                             | Default                 | "Failed to extract indicator from diff line"                |
| 95  | Removed File Bad Indicator   | Tests that removed files reject lines with positive (+) indicators instead of expected negative (-) indicators.                                          | Default                 | "Expected negative or backslash indicator for removed file" |
| 96  | Bad Hunk Header              | Tests that malformed hunk headers that don't match the expected `@@ -X,Y +A,B @@` format are rejected.                                                   | Default                 | "Unrecognized hunk info"                                    |
| 97  | Binary Path Extraction Error | Tests that malformed binary file diff lines that don't match the expected "Binary files ... differ" format are properly rejected.                        | Default                 | "Path info for binary file not found"                       |
| 98  | Invalid Color Hex            | Tests that color parameters containing letters (like hex codes) are rejected. Verifies that only numbers and semicolons are allowed in color parameters. | `color_line_number=3a2` | "color parameters may contain only numbers and semi-colons" |
| 99  | Bad Path Format Error        | Tests that malformed path lines with invalid formats (neither standard prefix nor --no-prefix format) are properly rejected.                             | Default                 | "sanity check failed, expected"                             |

### Unreachable Error Conditions

The following error conditions exist in the code as defensive checks but are not reachable with any input:

- **"Path info not found" (line 632)**: Would require processing diff content without path headers after exiting header parsing mode. However, exiting header parsing only happens when encountering a `@@` hunk header, which triggers "Line info found before path info" (test 91) first if path headers are missing.

- **"Line info not found" (line 638)**: Would require missing hunk header info when processing diff content. However, the hunk header processing always sets `found_line=1` before this check is reached.

These represent sound defensive programming practices, even though they cannot be triggered in practice.

## Adding New Tests

To add a new test:

1. Create an input file: `tests/inputs/XXX_test_name.diff`
2. Create expected output: `tests/outputs/XXX_test_name.out`
3. (Optional) Add arguments: `tests/inputs/XXX_test_name.args`
4. (Optional) For error tests: `tests/outputs/XXX_test_name.error`
5. Update this README with test description
6. Run `./run_tests.sh` to verify

## Test Coverage

The test suite provides comprehensive coverage of all major features and edge cases:

### Core Functionality

- ✓ Basic diff operations (additions, deletions, unchanged lines)
- ✓ File operations (new files, removed files, multiple files)
- ✓ Binary files (modified, removed, with special characters in paths)
- ✓ Line number formatting and alignment (including boundary transitions)

### Display Options

- ✓ show_path, show_header, show_hunk, show_binary
- ✓ Color output (color_line_number, color_path, color_separator)
- ✓ allow_colons_in_path option

### Path and Format Handling

- ✓ All git diff prefixes (a/, b/, i/, w/, c/, o/)
- ✓ Quoted paths (paths with special characters)
- ✓ Paths with spaces and colons
- ✓ Multiple diff formats (standard, mnemonic)
- ✓ ANSI escape code handling in colored input

### Edge Cases

- ✓ Large line numbers (no scientific notation)
- ✓ Multiple hunks with large gaps
- ✓ Large unchanged context sections
- ✓ Single line hunks without explicit count
- ✓ Line number boundaries (e.g., 99→100)
- ✓ No newline at EOF warnings

### Error Conditions

- ✓ Combined diff format rejection
- ✓ Missing or malformed headers
- ✓ Invalid color parameters
- ✓ Invalid diff line indicators
- ✓ Malformed hunk headers
- ✓ Path validation (forbidden colons)

## Notes

- Tests use `gawk` (GNU AWK) which is required by showlinenum.awk
- The test runner compares exact output including whitespace
- Failed tests show a diff between expected and actual output
