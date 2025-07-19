# Testing Guideline for Zsh Scripts

This document provides comprehensive guidelines for writing effective BDD (Behavior-Driven Development) tests using ShellSpec in our image dataset preparation tools project.

## Overview

We use [ShellSpec](https://shellspec.info/) as our testing framework with a focus on:

- **85%+ coverage** requirement for all zsh scripts
- **Behavior-Driven Development** (BDD) approach
- **Command-based mocking** for external dependencies
- **Comprehensive test scenarios** covering normal, edge, and error cases

## Project Structure

```text
spec/
├── .shellspec                  # ShellSpec configuration
├── spec_helper.sh             # Common test utilities
├── support/
│   └── fixtures/              # Test data files
├── *_spec.sh                  # Test files (one per script)
├── *_basic_spec.sh           # Basic functionality tests
├── *_functional_spec.sh      # Functional behavior tests
└── *_simple_spec.sh          # Simple integration tests
```

## Test File Structure

### Basic Template

```bash
#!/bin/zsh

eval "$(shellspec - -c) exit 1"
# Copyright (C) 2025 Jim Chen <Jim@ChenJ.im>, licensed under GPL-3.0-or-later
#
# Description of what this test file covers

# Include spec helper for common utilities
Include spec/spec_helper.sh

Describe 'script_name.zsh'
  setup() {
    setup_test_env
  }

  cleanup() {
    cleanup_test_env
  }

  Before 'setup'
  After 'cleanup'

  Describe 'Feature group description'
    It 'should describe specific behavior'
      When call command_to_test
      The status should be success
      The output should include "expected output"
    End
  End
End
```

### Essential Elements

1. **Shebang**: Always use `#!/bin/zsh`
2. **ShellSpec initialization**: `eval "$(shellspec - -c) exit 1"`
3. **GPL-3.0-or-later license header**
4. **Include spec_helper**: `Include spec/spec_helper.sh`
5. **Setup/cleanup hooks**: Use `Before`/`After` with helper functions

## BDD Test Structure

### Describe Blocks

Use `Describe` to group related tests:

```bash
Describe 'resize_images.zsh'
  Describe 'Image processing'
    # Tests for image processing functionality
  End

  Describe 'Error handling'
    # Tests for error scenarios
  End
End
```

### It Blocks

Use `It` to describe specific behaviors:

```bash
It 'should resize images larger than 1024px'
It 'should skip images already smaller than 1024px'
It 'should handle missing magick command gracefully'
```

### When Evaluations

Use `When` to execute the code being tested:

```bash
# For direct script execution
When run script "$SHELLSPEC_PROJECT_ROOT/script_name.zsh"

# For function calls
When call function_name arg1 arg2

# For script execution with arguments
When run script "$SHELLSPEC_PROJECT_ROOT/script_name.zsh" "arg1"
```

> [!IMPORTANT]
> **Coverage Measurement Target in ShellSpec**
>
> ShellSpec only measures coverage for shell scripts executed in specific ways:
>
> - Only scripts executed with `When run script` or `When run source` are included in coverage measurement.
> - Scripts executed with `When run zsh`, `When call zsh` or `When run command` (i.e., directly invoking zsh or another shell to run the script) are **not** included in coverage measurement.
> - Only `When run script`/`When run source` will execute in the same shell and allow correct coverage tracking.
>
> ```bash
> # Bad Practice, NEVER do this:
> When run zsh "$SHELLSPEC_PROJECT_ROOT/script_name.zsh"
> ```
>
> **Practical advice:**
>
> - For behavior/functional tests, always use `When run script "$SHELLSPEC_PROJECT_ROOT/script_name.zsh"` to ensure coverage is measured.
> - Use `When call zsh` only for syntax checking (e.g., `When call zsh -n`) or special cases (e.g., shebang behavior).
> - This ensures the coverage report accurately reflects the code exercised by your tests.

> [!TIP]
> See the ShellSpec official documentation: [Coverage Measurement Target](https://github.com/shellspec/shellspec/blob/master/README.md#measurement-target)

### The Expectations

Use `The` to assert expected outcomes:

```bash
The status should be success
The output should include "expected text"
The stderr should include "error message"
The file "filename.txt" should exist
The contents of file "test.txt" should equal "expected content"
```

## Mocking External Commands

### Command-Based Mocking

Use `Mock` blocks to simulate external commands:

```bash
Mock magick
  if [[ "$1" == "identify" ]]; then
    echo "1024 768"  # Mock image dimensions
  elif [[ "$1" == "convert" ]]; then
    # Mock successful conversion
    exit 0
  fi
End
```

### Complex Mocking Scenarios

```bash
Mock curl
  case "$1" in
    "-s")
      # Mock successful API response
      echo '{"data": [{"id": 1, "name": "test"}]}'
      ;;
    *)
      exit 1
      ;;
  esac
End
```

### Mocking User Input

```bash
# In spec_helper.sh, we have:
mock_user_input() {
  local input="$1"
  echo "$input"
}

# Use in tests:
It 'should handle user input'
  # The script will receive "test_input" when it reads from stdin
  When run script "$SHELLSPEC_PROJECT_ROOT/script.zsh" <<< "test_input"
End
```

## Test Environment Setup

### Using Helper Functions

```bash
# Always use these for consistent test environment
setup() {
  setup_test_env  # Creates temporary directory and changes to it
}

cleanup() {
  cleanup_test_env  # Cleans up temporary directory
}
```

### Creating Test Data

```bash
# Create test files
create_test_image "test.jpg" 1024 768
create_test_txt "test.txt" "sample content"

# Create complete test datasets
create_test_dataset "complete"     # Complete valid dataset
create_test_dataset "missing_txt"  # Missing text files
create_test_dataset "mixed_issues" # Various issues
```

## Common Test Patterns

### 1. Syntax Validation

> [!IMPORTANT]
> **All zsh syntax validation tests are centralized in `spec/framework_integration_spec.sh`.**
> Do **not** write syntax validation (`zsh -n ...`) in individual test files. This avoids duplication and ensures a single source of truth for syntax checks.

If you need to add or update syntax validation, only modify `spec/framework_integration_spec.sh`.

### 2. Empty Directory Handling

```bash
It 'should handle empty directory gracefully'
  When run script "$SHELLSPEC_PROJECT_ROOT/script_name.zsh"
  The status should be success
  The output should include "No files found"
End
```

### 3. File Processing

```bash
It 'should process existing files'
  touch test.jpg
  Mock magick
    echo "800 600"
  End
  
  When run script "$SHELLSPEC_PROJECT_ROOT/resize_images.zsh"
  The status should be success
  The output should include "Processing: test.jpg"
End
```

### 4. Error Handling

```bash
It 'should handle missing dependencies'
  export OLD_PATH="$PATH"
  export PATH="/nonexistent"
  
  When run script "$SHELLSPEC_PROJECT_ROOT/script_name.zsh"
  The status should be failure
  The stderr should include "command not found"
  
  export PATH="$OLD_PATH"
End
```

### 5. File Content Validation

```bash
It 'should modify file contents correctly'
  echo "original content" > test.txt
  
  When run script "$SHELLSPEC_PROJECT_ROOT/process_txt_files.zsh" "trigger"
  The contents of file test.txt should equal "trigger, original content"
End
```

## Best Practices

### 1. Test Organization

- **One test file per script**: `script_name_spec.sh`
- **Separate basic and functional tests**: Use `*_basic_spec.sh` and `*_functional_spec.sh`
- **Group related tests**: Use nested `Describe` blocks
- **Clear test descriptions**: Use descriptive `It` statements

### 2. Test Independence

- **Use setup/cleanup hooks**: Ensure clean state for each test
- **Avoid test dependencies**: Each test should run independently
- **Use temporary directories**: Never test in the project directory

### 3. Mocking Strategy

- **Mock external commands**: Use `Mock` blocks for external dependencies
- **Mock user input**: Use helper functions for interactive scripts
- **Simulate different scenarios**: Mock both success and failure cases

### 4. Assertion Quality

- **Be specific**: Use precise assertions rather than generic ones
- **Test multiple aspects**: Check status, output, stderr, and file changes
- **Use appropriate matchers**: Choose the right assertion type for each case

### 5. Coverage Considerations

- **Test normal paths**: Cover the happy path scenarios
- **Test edge cases**: Handle empty files, missing files, invalid input
- **Test error conditions**: Simulate failures and verify error handling
- **Test boundary conditions**: Test limits and edge values

## Advanced Patterns

### Parameterized Tests

```bash
Describe 'Multiple scenarios'
  Parameters
    "jpg" "1024x768"
    "png" "800x600"
    "gif" "640x480"
  End

  Example "should process $1 files with $2 dimensions"
    create_test_image "test.$1" "${2%x*}" "${2#*x}"
    
    When run script "$SHELLSPEC_PROJECT_ROOT/script.zsh"
    The status should be success
  End
End
```

### Data-Driven Tests

```bash
It 'should process different image formats'
  Data
    #|jpg 1024 768
    #|png 800 600
    #|gif 640 480
  End
  
  When call process_image_data
  The status should be success
End
```

### Pattern Matching

```bash
It 'should output progress information'
  When run script "$SHELLSPEC_PROJECT_ROOT/script.zsh"
  The output should match pattern "Processing: * files"
  The stderr should match pattern "*Loaded * active tag aliases*"
End
```

## Debugging Tests

### Using Dump

```bash
It 'should produce expected output'
  When call command_to_test
  Dump  # Shows stdout, stderr, and status for debugging
  The output should include "expected"
End
```

### Verbose Output

```bash
# Run tests with verbose output
shellspec --format documentation

# Run specific test file
shellspec script_name_spec.sh

# Run with coverage
shellspec --kcov ../coverage
```

## Common Pitfalls

1. **Forgetting to mock external commands**: Always mock dependencies like `magick`, `curl`, `jq`
2. **Not using absolute paths**: Always use `$SHELLSPEC_PROJECT_ROOT` for script references
3. **Ignoring cleanup**: Always use `After` hooks to clean up test environments
4. **Weak assertions**: Use specific assertions rather than just checking status
5. **Testing in project directory**: Always use temporary directories for file operations

## Testing Checklist

Before submitting your tests, verify:

- [ ] All external commands are mocked
- [ ] Tests use temporary directories
- [ ] Setup/cleanup hooks are properly implemented
- [ ] Tests are independent and can run in any order
- [ ] Coverage target (85%+) is met
- [ ] All edge cases and error conditions are tested
- [ ] Test descriptions are clear and descriptive
- [ ] GPL-3.0-or-later license header is included

## Running Tests

```bash
# Run all tests (at project root)
shellspec

# Run specific test file
shellspec script_name_spec.sh

# Run with coverage
shellspec --kcov

# Run with detailed output
shellspec --format documentation
```

For more detailed ShellSpec documentation, visit [https://shellspec.info/](https://shellspec.info/).
