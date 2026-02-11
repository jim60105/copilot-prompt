---
mode: agent
description: "This prompt is designed to guide the agent in rewriting Rust documentation comments, ensuring that all comments are written in English and adhere to the specified guidelines."
tools: ['codebase', 'editFiles', 'runCommands', 'search']
---
0. I may provide you with a method to find a list of files. 
   * If I do, you should use that method to find the files that need to be processed.
   * If I do not provide such a method, you should assume that the files are located in the `src/` directory of the codebase.
   * Upon successfully acquiring file or directory information, do not cease operations or pause execution; instead, proceed immediately to implement the subsequent procedural steps outlined herein.

1. Conduct a comprehensive review to ensure that **all documentation and comments are exclusively written in English**.

   * Any instance of Chinese text in documentation or code comments must be identified and corrected accordingly.
   * *Note:* The presence of Chinese characters in test case strings is permissible and does not require modification.
   * *Note:* If you one of the files is a Chinese report, you should not modify it. Focus on the rust source code files only.

2. Use the following command to search for occurrences of Chinese characters within the source code directory:

   * #runCommands `rg -n "[\u4e00-\u9fff]" src/`
     This command will recursively scan the `src/` directory and display line numbers for any matches involving Chinese characters.
   * #runCommands `cd src/ && cargo clippy -- -W missing_docs`
     This command will check for missing documentation comments in the Rust codebase, ensuring that all public items are documented.
   * The default location is 'src/', but if I provide another location later, please replace it with the one I specify.

3. Refer to the documentation standards outlined in the file #file:./docs/rustdoc-guidelines.md for precise guidance on the expected structure and style of documentation comments.

4. Ensure all corrections adhere strictly to these documentation guidelines to maintain consistency and readability across the codebase.

5. Repeat the search and revision process iteratively until the command returns no further occurrences that require modification.

   * Do not prompt for confirmation before proceeding to the next item.
   * You are expected to complete **all** necessary changes before reporting back.

---

Let's do this step by step.
