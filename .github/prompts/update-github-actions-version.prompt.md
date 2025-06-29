---
mode: 'agent'
description: "Add SLSA build-provenance attestations to existing GitHub Actions workflows."
tools: ['codebase', 'editFiles', 'fetch', 'githubRepo', 'runCommands']
---
# GitHub Actions Version Update Prompt

## Task Overview

When updating the versions of actions in GitHub Actions workflow files, follow these principles and steps.

## Important Principles

**⚠️ Key Reminder: Explanation of GitHub Actions Version Tagging System**

- Using a major version number (such as `v4`, `v5`, `v6`) will automatically fetch the latest minor and patch versions under that major version.
- For example, `actions/checkout@v4` will automatically get versions like `v4.2.2`, `v4.3.0`.
- **There is no need** to update from `v4` to a specific version like `v4.2.2`; this level of detail is unnecessary.
- **Only when originally specifying just the major version number should updates occur when there's a change in the major version** (e.g., from `v5` to `v6`).

## Execution Steps

### 0. Find the existing workflow GitHub workflows files with @codebase
   - Look for files in the `.github/workflows/` directory recursively
   - Note that there may be cases where composite actions are used, in which case you need to read both the composite action and the workflow file that calls it simultaneously.

### 1. Check Current Versions

Analyze the action versions used in the GitHub Actions workflow files.

### 2. Query Latest Versions

Use tools #fetch #githubRepo to query each action's latest version:

```
https://github.com/{owner}/{repo}/releases/latest
```

### 3. Identify Actions That Need Updating

**Only update actions where there has been a change in the major version**, for example:

- ✅ Needs updating: From `docker/build-push-action@v5` to `\@ v6`
- ❌ Does not need updating: From `\@ v4.actions/checkout @ v4 \to \@ v4 .2 .2`

> **Note:** Skip `fatjyc/update-submodule-action@v6.0` updates as the new version is broken and v6.0 is fine.

### 4. Obtain Changelog for Updated Actions 

For actions that require an update, retrieve changelogs to understand any breaking changes that need addressing.

### 5. Update Files 

Use the tool 'replace_string_in_file' to update necessary version numbers and make adjustments for any breaking changes required.

### 6. Commit Your Changes 

Execute the following #runCommands git commands; using terminal commands here is permitted:

```bash  
git add .github/workflows/docker_publish.yml # or whatever files you modified  
codegpt commit --no_confirm  
```

> **Note:** Ensure to call #runCommands `codegpt`, which is a tool optimized for git commit, do not write the commit message on your own.

## Example Illustration 

### ✅ Correct Update 

```yaml
# From
uses: docker/build-push-action@v5
# Update to 
uses: docker/build-push-action@v6
```

### ❌ Incorrect Update (Unnecessary)

```yaml
# From 
uses: actions/checkout@v4 
# Incorrectly updated to 
uses: actions/checkout@v4 .2 .2  
```

### ✅ Correct Practice (Keep Unchanged)

```yaml
# Keep unchanged 
uses :actions / checkout @ v 4  
GitHub will automatically use the latest v 4.x.x release   
```
