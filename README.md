# showlinenum

showlinenum.awk - show line numbers for git diff

[![Tests](https://github.com/jay/showlinenum/workflows/Tests/badge.svg)](https://github.com/jay/showlinenum/actions)

This gawk script modifies git diff output by prepending line numbers to each line of the diff.

[![screenshot](screenshot.png?raw=true)](screenshot.png?raw=true)

## Usage

`git diff [options] | showlinenum.awk [options]`

All options for showlinenum require a value and are specified using the format `option=value`.

Combined diff format is not supported.

## Output

The diff line output is in this format:
`[path:]<line number>:<diff line>`

When the path is shown, it represents the new version's file path. Line numbers are displayed for lines in the new version of the file (i.e., lines that are unchanged or added). If a line appears only in the old version of the file (i.e., lines removed) or the warning indicator is found, then padding space is used in place of a line number. If a file was removed, a tilde (~) is used in place of a line number.

The first character in `<diff line>` is one of four indicators:
`-` : Line removed
`+` : Line added
` ` : Line unchanged
`\` : Diff warning about previous line

For example:

```
 :-removed
7:+added
8: common
 :\ No newline at end of file
```

The backslash indicator is used exclusively for the missing newline at end of file warning. When this warning appears, it applies to the line immediately above it. In the example above, both the old and new versions of the compared file are missing the newline at EOF. If the line above a warning is a removed line, the warning applies to the old version of the file. If the line above a warning is an added line, the warning applies to the new version of the file.

All errors are sent to standard error output (stderr). All errors are treated as fatal. When a fatal error occurs, a line starting with `FATAL:` is output, followed by the script name and error message(s), which may span one or more lines. The script then aborts with exit code 1.

## Examples

Basic usage with line numbers prepended to git diff output:
`git diff --cached | showlinenum.awk`

This script properly handles ANSI escape color codes output by git diff. To enable color output, pass `--color=always` to git diff. Note that this forces color output in all cases, so it is recommended only when outputting to a terminal or to a destination that can properly handle color codes. Many scripts do not function correctly with color-coded input.

Same as the first example, with color output enabled:
`git diff --color=always --cached | showlinenum.awk`

Options can be passed using awk's `-v` option or by appending them directly:
`git diff --color=always HEAD~1 HEAD | showlinenum.awk show_header=0`
`git diff --color=always HEAD~1 HEAD | showlinenum.awk show_path=1 show_hunk=0`

## Options

### Show diff headers

#### `show_header [0,1] default: 1`

Example:

```
diff --git a/abc.c b/abc.c
index 285065f..2471f87 100644
--- a/abc.c
+++ b/abc.c
```

### Show line hunks

#### `show_hunk [0,1] default: ( show_header ? 1 : 0 )`

Example: `@@ -0,0 +1,17 @@`

### Show paths before line numbers

#### `show_path [0,1] default: ( show_header ? 0 : 1 )`

Example:
`testdir/file:39:+some added text`

### Show binary files in empty format

#### `show_binary [0,1] default: ( show_path ? 1 : 0 )`

Binary files have no concept of lines; therefore, there is no line number or diff content to indicate that a binary file differs. When headers are shown, the message "Binary files &lt;old&gt; and &lt;new&gt; differ" indicates binary file changes. When headers are not shown, this message is suppressed and a binary file that differs has an "empty format" (`[path:][~]:`) with no information, except for a tilde if the file was removed.

Examples of the empty format with and without path shown:
`testdir/binary_file::`
`:`

Example of a removed binary file with path shown:
`calc.exe:~:`

### Allow colons in path

#### `allow_colons_in_path [0,1] default: ( show_path ? 0 : 1 )`

When this option is disabled, the script aborts if a path containing a colon is encountered. This guarantees that the script's diff line output can always be parsed with the first colon occurring immediately after the full path. Note that git diff paths may start with `<commit>:` (e.g., `HEAD:./foo/bar`); for such paths, this option must be enabled.

_Prior to [db79583](https://github.com/jay/showlinenum/commit/db79583) this option defaulted to off always._

### Add color to sections

#### `color_{line_number,path,separator} <num>[;num][;num]`

Colors the respective section using one or more [ANSI color codes](https://user-images.githubusercontent.com/965580/27257186-e5709826-539a-11e7-9dcb-414fa65a0fbe.png). Recommended only when outputting to a terminal. If semicolons are present in these options, your shell may require them to be quoted.

Example: `color_line_number=1;37;45` specifies bright white foreground (1;37) on purple background (45).

[![color_line_number](color_line_number.gif?raw=true)](color_line_number.gif?raw=true)

## Testing

showlinenum includes a comprehensive test suite covering all features and edge cases. Tests are automatically run via GitHub Actions CI on every push and pull request.

To run tests locally:

```bash
cd tests
./run_tests.sh
```

For detailed information about the test suite, including descriptions of all test cases, see [tests/README.md](tests/README.md).

## Other

### License

showlinenum is free software licensed under the [GNU General Public License version 3 (GPLv3)](http://www.gnu.org/copyleft/gpl.html). Under the terms of this license, you may not remove the copyright of the author or any contributors. The source code for showlinenum cannot be used in proprietary software; however, you may execute a free software application from a proprietary software application. Please review the GPLv3 license for complete terms and conditions.

### Source

The source code is available on [GitHub](https://github.com/jay/showlinenum).

### Contact

For questions or issues, contact Jay Satiro at `<raysatiro$at$yahoo{}com>` with "showlinenum" in the subject line.
