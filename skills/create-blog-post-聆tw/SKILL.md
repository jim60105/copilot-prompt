---
name: create-blog-post-聆tw
description: >
  Create a new tech blog post on 聆.tw (琳聽智者漫談), a Traditional Chinese AI-assisted tech blog.
  Use when the user wants to write a new blog post, create an article, draft a tech article,
  or publish content on 聆.tw. Triggers on requests like "write a blog post", "create an article about X",
  "draft a post on 聆.tw", or "help me write about X for the blog".
  This skill handles the full workflow: repo setup, content creation, writing in Traditional Chinese
  following strict editorial guidelines, and submitting a pull request.
---

# Create Blog Post on 聆.tw

This skill guides the full workflow of creating a new tech blog post on **聆.tw** (琳聽智者漫談), from repo setup to PR submission.

## Prerequisites

- `git` CLI available
- `gh` CLI authenticated with GitHub
- Write access to `jim60105/ai-talks-content`

## Workflow

### Step 1: Clone the Repository

If the blog repo is not yet cloned:

```bash
git clone --recurse-submodules https://github.com/jim60105/blog.git
cd blog
```

If already cloned but submodules are missing:

```bash
git submodule update --init --recursive
```

If already cloned and submodules exist, just ensure they're up to date:

```bash
git pull origin master
```

### Step 2: Prepare the Submodule

Enter the content submodule and ensure it's on the latest `master`:

```bash
cd 聆.tw/content
git checkout master
git pull origin master
cd ../..
```

### Step 3: Switch to 聆.tw Mode

From the project root (`blog/`):

```bash
./switch-site.sh 聆.tw
```

This creates symlinks for `config.toml`, `content/`, `static/`, and `wrangler.jsonc` pointing to `聆.tw/`.

### Step 4: Choose Section and Prepare File

List available content sections:

```bash
ls -d 聆.tw/content/*/
```

Choose the section most related to the topic. If none fits well, use `Uncategorized`.

### Step 5: Create the Post File

Create a markdown file with a slugified filename (lowercase, hyphens, English, descriptive):

```bash
touch 聆.tw/content/<Section>/my-descriptive-slug.md
```

Naming convention: use lowercase English words separated by hyphens. The slug should describe the post content concisely.

### Step 6: Write Front Matter

Read `AGENTS.md` at the project root for the latest front matter specification. The required format:

```toml
+++
title = "文章標題（正體中文）"
description = "SEO 友善的文章描述，包含所有重要關鍵字（正體中文）"
date = "YYYY-MM-DDTHH:MM:SSZ"
updated = "YYYY-MM-DDTHH:MM:SSZ"
draft = false

[taxonomies]
tags = ["Tag1", "Tag2"]
providers = [ "Felo Search" ]

[extra]
withAI = "<https://the.ai.resource/used>"
+++
```

Rules:

- `title`: Concise, SEO-friendly, Traditional Chinese
- `description`: Contains all keywords, compelling for search results
- `date`: ISO 8601 UTC format, use current timestamp
- `updated`: ISO 8601 UTC format, use current timestamp
- `tags`: Relevant tags in the format used by existing posts
- `providers`: The provider(s) of AI assistance used in writing the article, if any
- `withAI`: Brief note about AI assistance or any urls to AI resources used. This is optional but recommended for transparency.
- **NEVER** fabricate an `iscn` field — only the user can generate this

### Step 7: Write the Blog Post Content

Read `.github/instructions/quill-sage.instructions.md` at the project root for full editorial guidelines. For quick reference, see [references/writing-guidelines.md](references/writing-guidelines.md).

Key rules:

- Write in **Traditional Chinese** (zh-TW) with full-width punctuation
- Add a space between Chinese characters and alphanumeric characters
- Use inverted pyramid structure: core conclusion first, evidence second
- Avoid bullet lists unless explicitly requested; prefer natural paragraphs
- Use `##` and `###` subheadings to organize
- Address reader as 「讀者」「大家」「各位」 or 「你」, never 「您」
- Refer to the author as 「我」, never 「我們」
- Opening paragraph states core conclusion and scope
- Closing paragraph must not use slogan-style endings

### Step 8: Add Formatting and Color Shortcodes

Review the article and enhance with:

- **Bold** (`**text**`) for emphasis keywords
- *Italic* (`*text*`) where appropriate
- Color shortcodes for pros/cons:
  - Green (positive): `{{ cg(body="positive text") }}` or `{% cg() %}block text{% end %}`
  - Red (negative): `{{ cr(body="negative text") }}` or `{% cr() %}block text{% end %}`

### Step 9: Add Chat Shortcodes

Use chat shortcodes to create conversational content that makes the article vivid:

```markdown
{% chat(speaker="yuna") %}
Question or statement from Yuna
{% end %}

{% chat(speaker="jim") %}
Response from Jim (author, displayed as 琳, aligned right)
{% end %}
```

Available speakers: `chatgpt`, `claude`, `gemini`, `copilot`, `felo`, `jim` (author, right-aligned), `yoruka`, or any custom name. Default/`user` gets a generic user avatar.

Design conversations that naturally introduce the topic, ask clarifying questions, or surface interesting angles. The chat format should add value, not just decorate.

### Step 10: SEO Review — Rewrite Title and Description

After completing the content, re-evaluate:

1. **Title**: Rewrite for SEO. Include the primary keyword near the front. Keep it concise but descriptive. Traditional Chinese.
2. **Description**: Rewrite to include all important keywords from the article. This text appears in search results — make it compelling and informative. ~150-160 characters ideal.

### Step 11: Rename File if Title Changed

If the title was significantly revised, rename the file to match:

```bash
mv 聆.tw/content/<Section>/old-slug.md 聆.tw/content/<Section>/new-better-slug.md
```

The slug should reflect the final title content in English.

### Step 12: Create Branch, Commit, and PR

All git operations happen **inside the submodule** (`聆.tw/content/`):

```bash
cd 聆.tw/content
git checkout -b post/<slug-name>
git add <Section>/new-post-file.md
git commit --signoff --author="GitHub Copilot <bot@ChenJ.im>" -m "feat: add post <descriptive-title>

Add new blog post about <topic summary>.

Co-authored-by: GitHub Copilot <bot@ChenJ.im>"
git push origin post/<slug-name>
```

Then create the PR targeting `master` on `jim60105/ai-talks-content`:

```bash
gh pr create \
  --repo jim60105/ai-talks-content \
  --base master \
  --head post/<slug-name> \
  --title "feat: add post <descriptive-title>" \
  --body "Add new blog post: <title>

<brief description of content>

---
Written with AI assistance."
```

### Step 13: Request Review

```bash
gh pr edit --repo jim60105/ai-talks-content <PR_NUMBER> --add-reviewer jim60105
```

## Terminology Mappings

When writing content, apply these Traditional Chinese mappings: create = 建立, object = 物件, queue = 佇列, stack = 堆疊, information = 資訊, code = 程式碼, running = 執行, library = 函式庫, building = 建構, package = 套件, video = 影片, class = 類別, function = 函式, memory = 記憶體, document = 文件, example = 範例, tutorial = 指南.
