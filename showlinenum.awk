#!/bin/sh
#
# Copyright (C) 2013 Jay Satiro <raysatiro@yahoo.com>
#
# This file is part of the showlinenum project.
# https://github.com/jay/showlinenum/
#
# This file is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This file is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this file. If not, see <http://www.gnu.org/licenses/>.
#
################################################################################
#
# DESCRIPTION
#
# This gawk script enhances git diff output by prepending line numbers to each
# line, making it easier to identify the location of changes in files.
#
################################################################################
#
# USAGE
#
# git diff [options] | showlinenum.awk [options]
#
# All options for showlinenum require a value and are specified using the
# format option=value.
#
# This script supports both standard git diff format and --no-prefix format.
#
################################################################################
#
# OUTPUT FORMAT
#
# The diff line output follows this format:
# [path:]<line number>:<diff line>
#
# When the path is shown, it represents the new version's file path. Line
# numbers are displayed for lines in the new version of the file (lines that
# are unchanged or added). For lines that appear only in the old version
# (removed lines) or for diff warnings, padding space is used in place of a
# line number. For removed files, a tilde (~) is used in place of a line number.
#
# The first character in <diff line> is one of four indicators:
# -       : Line removed
# +       : Line added
# <space> : Line unchanged
# \       : diff warning about previous line
#
# Examples:
#  :-removed
# 7:+added
# 8: common
#  :\ No newline at end of file
#
# The backslash indicator is used exclusively for the missing newline at EOF
# warning. When this warning appears, it applies to the line immediately above
# it. In the example above, both the old and new versions of the file are
# missing the newline at EOF. If the line above a warning is a removed line,
# the warning applies to the old version; if it's an added line, the warning
# applies to the new version.
#
# ERROR HANDLING
#
# All errors are sent to standard error (stderr). All errors are treated as
# fatal. On fatal error, a line starting with 'FATAL:' is followed by the
# script name and error message(s), which may span multiple lines. The script
# then aborts with exit code 1.
#
################################################################################
#
# EXAMPLES
#
# Basic usage - prepend line numbers to git diff output:
#   git diff --cached | showlinenum.awk
#
# Using --no-prefix format (removes a/ and b/ prefixes from paths):
#   git diff --no-prefix | showlinenum.awk
#   git diff --no-prefix --cached | showlinenum.awk
#
# Color output support:
# This script properly handles ANSI escape color codes from git diff. To enable
# color output, use --color=always. Note that color output should only be used
# when outputting to a terminal or a system that can properly handle ANSI color
# codes. Many scripts do not function correctly with color-coded input.
#
#   git diff --color=always --cached | showlinenum.awk
#   git diff --color=always --no-prefix | showlinenum.awk
#
# Passing options:
# Options can be passed using awk's -v option or the traditional format shown:
#   git diff --color=always HEAD~1 HEAD | showlinenum.awk show_header=0
#   git diff --color=always HEAD~1 HEAD | showlinenum.awk show_path=1 show_hunk=0
#   git diff --no-prefix HEAD~1 HEAD | showlinenum.awk show_path=1
#
################################################################################
#
# OPTIONS
#
# show_header [0,1]
#   Default: 1
#   Show diff headers.
#
#   Example:
#     diff --git a/abc.c b/abc.c
#     index 285065f..2471f87 100644
#     --- a/abc.c
#     +++ b/abc.c
#
# show_hunk [0,1]
#   Default: (show_header ? 1 : 0)
#   Show hunk headers.
#
#   Example: @@ -0,0 +1,17 @@
#
# show_path [0,1]
#   Default: (show_header ? 0 : 1)
#   Show file paths before line numbers.
#
#   Example:
#     testdir/file:39:+some added text
#
# show_binary [0,1]
#   Default: (show_path ? 1 : 0)
#   Show binary files that differ in an empty format: [path:][~]:
#
#   Binary files have no line-based representation, so there is no line number
#   or diff content to display. When headers are shown, binary file changes are
#   indicated by the message "Binary files <old> and <new> differ". When headers
#   are hidden, binary file changes are shown in an "empty format" containing
#   only the path (if enabled) and a tilde (~) for removed files.
#
#   Examples (empty format):
#     testdir/binary_file::
#     :
#
#   Example (removed binary file with path):
#     calc.exe:~:
#
# allow_colons_in_path [0,1]
#   Default: (show_path ? 0 : 1)
#   Allow colons in file paths.
#
#   When disabled, the script will abort if a path containing a colon is
#   encountered. This ensures the output can be reliably parsed using the first
#   colon as a separator after the file path. Note that git diff paths may
#   include commit references with colons (e.g., HEAD:./foo/bar), which require
#   this option to be enabled.
#
# color_line_number, color_path, color_separator
#   Format: <num>[;num][;num]
#   Add ANSI color codes to the respective sections.
#
#   Colors are specified using one or more ANSI color codes separated by
#   semicolons. This option should only be used when outputting to a terminal.
#   Shell quoting may be required if semicolons are present.
#
#   Example: color_line_number=1;37;45
#     Bright white foreground (1;37) on purple background (45)
#
################################################################################
#


{
# Launcher block: This code is compatible with both bourne shell and gawk.
# If the script is being interpreted by the bourne shell, gawk is executed
# to become the interpreter for this script.
LAUNCHER="" "exec" "gawk" "-f" "$0" "$@"
}


# Reset all header-related parsing variables to their initial state
function reset_header_variables()
{
  parsing_diff_header = 0;
  found_path = 0;
  path = 0;
  found_oldfile_path = 0;
  oldfile_path = 0;
  found_line = 0;
  line = 0;
  found_diff = 0;
  diff = 0;
}

# Initialize all script variables and validate color parameters
function init()
{
  reset_header_variables();

  # Force define variables as strings by appending an empty string. This is
  # necessary to prevent warnings in gawk --lint mode when testing whether a
  # variable was defined on the command line.

  # Initialize color variables
  color_line_number = color_line_number "";
  color_path = color_path "";
  color_separator = color_separator "";

  die_if_bad_color(color_line_number);
  die_if_bad_color(color_path);
  die_if_bad_color(color_separator);

  # Initialize boolean variables (converted to numbers by get_bool())
  show_header = show_header "";
  show_hunk = show_hunk "";
  show_path = show_path "";
  show_binary = show_binary "";
  allow_colons_in_path = allow_colons_in_path "";

  # Convert variables to boolean values or use defaults
  show_header = get_bool(show_header, 1);
  show_hunk = get_bool(show_hunk, (show_header ? 1 : 0));
  show_path = get_bool(show_path, (show_header ? 0 : 1));
  show_binary = get_bool(show_binary, (show_path ? 1 : 0));
  allow_colons_in_path = get_bool(allow_colons_in_path, (show_path ? 0 : 1));
}

# Print a fatal error message to stderr and exit with code 1
function FATAL(a_msg)
{
  print "";
  # Note: There is no portable way to get the script's name at runtime
  print strip_ansi_color_codes("FATAL: showlinenum: " a_msg) > "/dev/stderr";
  exit 1;
}

# Return the boolean numeric value of 'input' if it contains a valid boolean
# value (0 or 1), otherwise return the numeric value of 'a_default_value'
function get_bool(input, a_default_value)
{
  if(a_default_value !~ /^[0-1]$/)
  {
    errmsg = "get_bool(): a_default_value must be a bool value." \
             "\n" "a_default_value: " a_default_value;
    FATAL(errmsg);
  }

  regex = "^[[:blank:]]*([0-1])[[:blank:]]*$";
  if(input ~ regex)
  {
    return gensub(regex, "\\1", 1, input) + 0;
  }

  return a_default_value + 0;
}

# Validate that a color parameter contains only numbers and semicolons
# Abort with a fatal error if invalid characters are found
function die_if_bad_color(input)
{
  if(input ~ /[^0-9;]/)
  {
    errmsg = "die_if_bad_color(): color parameters may contain only numbers " \
             "and semi-colons.";
    FATAL(errmsg);
  }
}

# Fix an extracted path by removing git diff prefix and trailing tabs
# Example: '+++ b/foo/bar' with input 'b/foo/bar' returns 'foo/bar'
# Also handles --no-prefix format where paths have no prefix
function fix_extracted_path(input)
{
  if(input == "/dev/null")
  {
    return input;
  }

  # Check if path has a git diff prefix (for standard format)
  # or no prefix (for --no-prefix format)
  if(input !~ /^\042?([abiwco]\/|[^\/])/)
  {
    errmsg = "fix_extracted_path(): sanity check failed, expected [abiwco]/ " \
             "prefix or --no-prefix format." \
             "\n" "Path: " input;
    FATAL(errmsg);
  }

  if(!allow_colons_in_path && (input ~ /:/))
  {
    errmsg = "fix_extracted_path(): colons in path are forbidden ";
    if(show_path)
    {
      errmsg = errmsg "by default when show_path is on in deference to " \
               "scripts which may parse this script's output and rely on " \
               "the colon as a separator. To override use command line " \
               "option allow_colons_in_path=1.";
    }
    else
    {
      errmsg = errmsg "because allow_colons_in_path is off.";
    }
    errmsg = errmsg "\n" "Path: " input;
    FATAL(errmsg);
  }

  # Remove erroneous trailing tab that git diff can add to some non-binary
  # paths. For example, an unquoted 'b/a $b\t' becomes 'b/a $b' if the diff
  # line only contains the latter form.
  if((input ~ /\t$/) && !index(diff, input) && \
     index(diff, substr(input, 1, length(input) - 1)))
  {
    sub(/\t$/, "", input);
  }

  # Remove the git diff prefix (a/, b/, i/, w/, c/, o/) if present
  # This handles both standard format (with prefix) and --no-prefix format
  sub(/^[abiwco]\//, "", input);

  return input;
}

# Return a string with all ANSI color codes removed
function strip_ansi_color_codes(input)
{
  return gensub(/\033\[[0-9;]*m/, "", "g", input);
}

# Print a separator with optional color formatting
function print_separator(a_separator)
{
  if(color_separator)
  {
    printf "\033[%sm%s\033[m", color_separator, a_separator;
  }
  else
  {
    printf "%s", a_separator;
  }
}

# Print a line number with optional color formatting and uniform width
function print_line_number(a_line_number)
{
  if(color_line_number)
  {
    printf "\033[%sm", color_line_number;
  }

  if(a_line_number ~ /^[0-9]+$/)
  {
    # Awk stores all integers internally as floating point. Printf may convert
    # large integers to scientific notation, which is undesirable for line
    # numbers. The 'f' type specifier with %.0f prevents this and handles the
    # range [-9007199254740992, 9007199254740992] correctly.
    # Format with uniform width (right-aligned)
    printf "%*s", line_width, sprintf("%.0f", a_line_number + 0);
  }
  else
  {
    printf "%*s", line_width, a_line_number;
  }

  if(color_line_number)
  {
    printf "\033[m";
  }

  print_separator(":");
}

# Print a file path with optional color formatting (only if show_path is enabled)
function print_path(a_path)
{
  if(!show_path)
  {
    return;
  }

  if(color_path)
  {
    printf "\033[%sm%s\033[m", color_path, a_path;
  }
  else
  {
    printf "%s", a_path;
  }

  print_separator(":");
}

################################################################################
#
# MAIN PROCESSING
#
# Process each line of input from git diff and add line numbers
#
################################################################################
{
  # Initialize on first line of input
  if(NR == 1)
  {
    init();
  }

  # Process diff header line (e.g., "diff --git a/file b/file")
  if($0 ~ /^(\033\[[0-9;]*m)*diff /)
  {
    reset_header_variables();
    parsing_diff_header = 1;

    diff = strip_ansi_color_codes($0);
    found_diff = 1;

    if(show_header)
    {
      print;
    }

    next;
  }

  # Reject combined diff format (not supported)
  if($0 ~ /^(\033\[[0-9;]*m)*@@@+ /)
  {
    FATAL("Combined diff format not supported.");
  }

  # Process hunk header line (e.g., "@@ -10,7 +10,6 @@")
  if($0 ~ /^(\033\[[0-9;]*m)*@@ /)
  {
    line = 0;
    found_line = 0;
    parsing_diff_header = 0;

    if(!found_path || !found_oldfile_path)
    {
      FATAL("Line info found before path info.");
    }

    stripped = strip_ansi_color_codes($0);

    regex = "^@@ -[0-9]+(,[0-9]+)? \\+([0-9]+)(,([0-9]+))? @@.*$";
    if(stripped ~ regex)
    {
      # Extract starting line number from hunk header
      line = gensub(regex, "\\2", 1, stripped);
      # Convert string to integer (requires color codes to be removed first)
      line = line + 0;
      found_line = 1;

      # Calculate line number width for uniform formatting based on maximum
      # line number in this hunk
      line_count_str = gensub(regex, "\\4", 1, stripped);
      if(line_count_str ~ /^[0-9]+$/)
      {
        line_count = line_count_str + 0;
        if(line_count == 0)
        {
          # Removed file: only tilde markers (~) which are 1 character
          line_width = 1;
        }
        else
        {
          max_line = line + line_count - 1;
          line_width = length(max_line "");
        }
      }
      else
      {
        # No count specified means 1 line
        max_line = line;
        line_width = length(max_line "");
      }
    }

    if(!found_line)
    {
      errmsg = "Unrecognized hunk info.";
      if(path == "/dev/null")
      {
        errmsg = errmsg "\n" "Removed file: " oldfile_path;
      }
      else
      {
        errmsg = errmsg "\n" "File: " path;
      }
      errmsg = errmsg "\n" "File's hunk info: " stripped;
      FATAL(errmsg);
    }

    if(show_hunk)
    {
      print;
    }

    next;
  }

  # Parse diff header lines
  if(parsing_diff_header)
  {
    stripped = strip_ansi_color_codes($0);

    # Extract old file path from "---" line
    # Handles both standard format (a/file) and --no-prefix format (file)
    # Paths can contain spaces and extend to the end of the line
    regex = "^\\-\\-\\- (\\042?([aiwco]\\/)?.+|\\/dev\\/null)$";
    if(stripped ~ regex)
    {
      oldfile_path = fix_extracted_path(gensub(regex, "\\1", 1, stripped));
      found_oldfile_path = 1;

      if(show_header)
      {
        print;
      }

      next;
    }

    # Extract new file path from "+++" line
    # Handles both standard format (b/file) and --no-prefix format (file)
    # Paths can contain spaces and extend to the end of the line
    regex = "^\\+\\+\\+ (\\042?([biwco]\\/)?.+|\\/dev\\/null)$";
    if(stripped ~ regex)
    {
      path = fix_extracted_path(gensub(regex, "\\1", 1, stripped));
      found_path = 1;

      if(show_header)
      {
        print;
      }

      next;
    }

    # Handle binary file diff indicator
    regex = "^Binary files (.*) differ$";
    if(stripped ~ regex)
    {
      path = gensub(regex, "\\1", 1, stripped);

      found_path = 0;
      found_oldfile_path = 0;

      # Extract old file path for deleted or moved binary files
      # (indicated by "and /dev/null" in the binary files message)
      if(match(path, / and \/dev\/null$/))
      {
        oldfile_path = substr(path, 1, length(path) - RLENGTH);

        # Check for standard format (with prefix) or --no-prefix format
        if(((oldfile_path ~ /^\042?[aiwco]\//) || (oldfile_path !~ /^\042?and /)) && index(diff, oldfile_path))
        {
          oldfile_path = fix_extracted_path(oldfile_path);
          found_oldfile_path = 1;
          path = "/dev/null";
          found_path = 1;
        }
      }

      # Extract new file path for binary files by finding the longest rightmost
      # match between the diff header line and the binary files notice line
      # Handles both standard format (b/file) and --no-prefix format (file)
      while(!found_path && match(path, /and \042?([biwco]\/)?.+$/))
      {
        path_len = RLENGTH - 4;
        path = substr(path, RSTART + 4, path_len);

        diff_rstart = (length(diff) + 1) - path_len;
        if(diff_rstart < 1)
        {
          continue;
        }

        if(path == substr(diff, diff_rstart, path_len))
        {
          path = fix_extracted_path(path);
          found_path = 1;
          break;
        }
      }

      if(show_header)
      {
        print;
      }

      if(!found_path && !found_oldfile_path)
      {
        errmsg = "Path info for binary file not found in header lines." \
                 "\n" "Diff line: " diff \
                 "\n" "Current line: " stripped;
        FATAL(errmsg);
      }

      if(show_binary)
      {
        if(found_oldfile_path)
        {
          # Binary file removed: path/to/foo:~:
          print_path(oldfile_path);
          print_line_number("~");
        }
        else
        {
          # Binary file differs: path/to/foo::
          print_path(path);
          print_line_number("");
        }

        print "";
      }

      reset_header_variables();
      next;
    }

    if(show_header)
    {
      print;
    }

    next;
  }

  # Validate that required path information has been found
  if(!found_path || !found_oldfile_path)
  {
    FATAL("Path info not found.");
  }

  # Validate that hunk line information has been found
  if(!found_line)
  {
    FATAL("Line info not found.");
  }

  # Handle removed files (new path is /dev/null)
  if(path == "/dev/null")
  {
    if($0 !~ /^(\033\[[0-9;]*m)*[\\-]/)
    {
      errmsg = "Expected negative or backslash indicator for removed file's " \
               "diff line." \
               "\n" "Removed file: " oldfile_path \
               "\n" "File's diff line: " $0;
      FATAL(errmsg);
    }

    # Format: path/to/foo:~:-removed line
    print_path(oldfile_path);
    print_line_number("~");

    print;
    next;
  }

  # Extract the diff line indicator (+, -, space, or backslash)
  # Note: Early versions of gawk (e.g., Git for Windows) do not support array
  # parameters for match(), so substr() is used instead.

  if(($0 !~ /^(\033\[[0-9;]*m)*[\\ +-]/) || \
     !match($0, /[\\ +-]/) || (RLENGTH != 1))
  {
    errmsg = "Failed to extract indicator from diff line." \
             "\n" "File: " path \
             "\n" "File's diff line: " $0;
    FATAL(errmsg);
  }

  indicator = substr($0, RSTART, RLENGTH);

  # Process added or unchanged lines (show line number and increment)
  if((indicator == "+") || (indicator == " "))
  {
    print_path(path);
    print_line_number(line++);
  }
  # Process removed lines or warnings (show padding instead of line number)
  else if((indicator == "-") || (indicator == "\\"))
  {
    print_path(path);
    print_line_number("");
  }
  else
  {
    errmsg = "Unexpected diff line indicator." \
             "\n" "Indicator: " indicator \
             "\n" "File: " path \
             "\n" "File's diff line: " $0;
    FATAL(errmsg);
  }

  print;
}
