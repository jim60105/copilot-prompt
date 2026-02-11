---
mode: agent
description: "Create a new Azure DevOps wiki page"
---
I am going to write a new wiki page now. Please:

1. #runCommands execute `tree . /f` in pwsh to get all the page lists.
2. Read all the doc under 01-設計文件 and 02-功能需求 and 04-標準規範 with #search #readFile, to get the full view of our project. (Don't read the file through #runCommands)
3. #think ultrathink and plan about what to write in a wiki page about ${input:what-to-write-in-this-page}.
4. In addition to the text, include a mermaid diagram on the page if there is suitable content for it.
5. If the user doesn't specify, find an appropriate category and location path for this page.
6. Write the page in 正體中文
7. Add this page to `.order` file in the same directory
8. Add this page to the category's markdown file. (For example, if the page is under `04-標準規範/`, update `04-標準規範.md`.)
9. Review whether your Azure DevOps Wiki is well-written; in this step, you should refine the page to improve it.
10. Git commit with good message body.
11. Well done! Summarize and tell me what you have done.

Let's do this step by step.

---

How to write a good wiki:

- Write in simple, concise language.
- Follow a consistent format across all pages.
- Break up sections with headlines, subheads, and text boxes.
- Enrich pages with mermaid diagrams and links.
- Include a list of FAQs in each section.
