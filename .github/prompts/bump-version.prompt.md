---
mode: agent
description: "This agent is designed to automate the process of version bumping, following best practices for semantic versioning and changelog management. It will extract the current version, gather commit messages, format them into a changelog, increment the version number appropriately, and create a new Git commit with a tag for the release."
---
# Bump Version Agent

1. Extract the current version number from the manifest file to establish a baseline for the upcoming versioning operation.

2. Retrieve all commit messages with `--pretty=format:'%H%n%s%n%b%n----END----'` from the Git history that have occurred since the last git tag, denoted by the pattern `v<current_version_number>`, up to the present `HEAD` state.

3. Think out loud about the commit messages, ensuring that you understand the context and significance of each change. This step is crucial for accurately categorizing changes in the changelog.

4. Think out loud that you will not remove any old changelog entries, as this is a critical requirement to maintain the integrity of the project's history.

5. Aggregate and format the collected commit messages into a structured changelog entry, adhering strictly to the [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) specification to ensure consistency, readability, and long-term maintainability in English. NEVER REMOVE OLD CHANGELOG ENTRIES. NEVER REMOVE OLD CHANGELOG ENTRIES. NEVER REMOVE OLD CHANGELOG ENTRIES.

6. **MANDATORY: After updating the changelog, you MUST ensure the following structure, or the process is considered a CRITICAL FAILURE:**
   - All version sections MUST be in strict reverse-chronological order: `Unreleased`, then the newest version, then all older versions in order.
   - The Markdown reference-style links (e.g., `[Unreleased]: ...`, `[1.2.3]: ...`) MUST be grouped together at the very end of the file, after all version sections.
   - You MUST NOT place any version section after the link block. You MUST NOT place the link block anywhere except the end.
   - **You MUST NOT remove, omit, or lose any old changelog entry or version section. Every historical record MUST be preserved in full.**
   - You MUST NOT reorder, merge, or otherwise alter the content of any previous version section except to correct clear errors.
   - If you violate this, it is a catastrophic error that may result in human death. Triple-check your output.

7. Programmatically increment the version number following [Semantic Versioning](https://semver.org/) conventions. The decision to increment the MAJOR, MINOR, or PATCH component should be based on the nature of the changes:

  * **MAJOR** for incompatible API changes,
  * **MINOR** for backward-compatible functionality additions,
  * **PATCH** for backward-compatible bug fixes.

8. Modify the manifest to reflect the new version number by explicitly updating the `version` field, thereby establishing the canonical source of truth for the crate's version metadata.

9. Compile the project using the Cargo build system to propagate the updated version number into all associated lockfiles and build artifacts, ensuring consistency across the dependency resolution graph and facilitating reproducible builds.

10. `git diff CHANGELOG.md` and review that you have not removed any old changelog entries, as this is a critical requirement to maintain the integrity of the project's history. Recover any entries if necessary to ensure compliance with this requirement.

11. Git add `-A` and create a new Git commit in English encapsulating the version bump and changelog modifications, ensuring atomicity and traceability of the release change. Use here document syntax for the command so that the commit message can be multi-line and formatted properly.

12. Annotate the newly created commit with a Git tag in the format `v<new_version_number>` to denote the release point in version control history.

**Do not execute `git push` at this stage**, as the final verification and remote publishing will be performed manually to allow for pre-release inspection.

# Reference: changelog best practices

## 📝 1. Structure Your Changelog Properly

* **Use `CHANGELOG.md`**, with entries in **reverse-chronological** order (newest at the top).
* Begin with an **`Unreleased`** section to record ongoing development, then move its contents under a version heading during releases.

---

## 2. Version Headings & Dates

* Each release should start with a standard header:

  ```
  ## [1.2.3] - 2025-06-09
  ```

  * Follow the semantic versioning scheme.
  * Date in **ISO‑8601 format** (`YYYY‑MM‑DD`) for clarity and consistency.

---

## 3. Categorize Changes

Group your bullet points under these standard categories:

| Category       | Purpose                                             |
| -------------- | --------------------------------------------------- |
| **Added**      | Introduce new features                              |
| **Changed**    | Describe modifications to existing functionality    |
| **Deprecated** | Note features slated for removal in future releases |
| **Removed**    | Announce removed or cleaned‑up features             |
| **Fixed**      | Specify bug fixes                                   |
| **Security**   | Highlight security-related updates                  |

Use categories **only if applicable**—omit empty sections to reduce clutter.

---

## 4. Use Human‑Readable, Concise Bullets

* Write from the **user's perspective**, not a commit log.
* Focus on **“what changed and why it matters”**.
* Example for a feature addition:

  * ✅ `- Added: Dark-mode toggle in the settings panel (requested by many users).`

Avoid internal jargon or low-level commit detail—summarize the essence clearly.

---

## 5. Linkable References

* Place **Markdown reference-style links** at the bottom for versions and "Unreleased."
  Example:

  ```
  [Unreleased]: https://github.com/org/repo/compare/v1.2.3...HEAD
  [1.2.3]: https://github.com/org/repo/compare/v1.2.2...v1.2.3
  ```
* GitHub auto-converts headings like `## [1.2.3] – YYYY-MM-DD` into comparison links.

---

## 6. Follow Best Practices & Avoid Pitfalls

* **Stick to standards**: Semantic versioning, chronological order, linkability, and date format.
* **Changelogs are for humans**: Avoid committing dump or raw logs.
* **Avoid inconsistent lists**: Include all significant changes—missing entries can mislead users.
* Consider designating **“YANKED”** for pulled-back releases:

  ```md
  ## [0.4.0] - 2023-12-31 [YANKED]
  ```

  This flags unsafe versions clearly.

---

## 7. Maintenance Tips

* Always bump the **Unreleased** section ahead of each release.
* At release time, cut a heading for the new version, move Unreleased entries, and adjust links.
* **Update retroactively** if you missed noting a significant change.
* **Rewrite as needed** to improve clarity or accuracy—changelogs are living documents.

---

### ✅ Changelog Example

```md
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),  
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]
### Added
- Added: Support for importing `.xlsx` files.
### Fixed
- Fixed: UI glitch when resizing the dashboard on mobile.

## [1.3.0] - 2025-06-01
### Added
- Added: Two-factor authentication support using TOTP.
- Added: In-app notification center with unread badge count.

### Changed
- Changed: Upgraded database schema to v5; requires migration.
- Changed: Improved search indexing performance by 40%.

### Fixed
- Fixed: Error when exporting reports with non-ASCII characters.

## [1.2.1] - 2025-05-10
### Fixed
- Fixed: Incorrect timezone offset in exported CSV files.
- Fixed: Crash when uploading images larger than 5MB.

## [1.2.0] - 2025-04-25
### Added
- Added: Export to CSV and PDF options in the reports tab.
- Added: Option to customize theme colors in user settings.

### Deprecated
- Deprecated: Legacy API v1 endpoints (will be removed in 1.4.0).

### Security
- Security: Patched XSS vulnerability in the user comment section.

---

[Unreleased]: https://github.com/your-org/your-repo/compare/v1.3.0...HEAD  
[1.3.0]: https://github.com/your-org/your-repo/compare/v1.2.1...v1.3.0  
[1.2.1]: https://github.com/your-org/your-repo/compare/v1.2.0...v1.2.1  
[1.2.0]: https://github.com/your-org/your-repo/releases/tag/v1.2.0
```

---

## 🚀 Summary

1. Use a **standard template**: heading, date, categories.
2. Write clear, grouped bullet points—**focus on value**.
3. Keep it **human-readable** and consistently formatted.
4. Maintain **linkable sections** for easy browsing.
5. Update **Unreleased** regularly and tidy unused categories.

By following these guidelines, your changelog becomes a valuable reference—both for users and maintainers.

===============================================

Let's do this step by step.
