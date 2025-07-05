---
# applyTo: '**/*.py'
---
## Python Code Guidelines
* All code comments must be written in **English**.
* Documentation and user interface text are authored in **English**.
* Function names follow the `snake_case` convention.
* Class names follow `PascalCase`.
* Constants use `UPPER_CASE`.
* Avoid Indent Hadouken, use fail first and early return.
* The use of @deprecated is prohibited. Whenever you want to use @deprecated, simply remove it and directly modify any place where it is used.
* Instead of concentrating on backward compatibility, greater importance is given to removing unnecessary designs. When a module is no longer utilized, remove it. DRY (Don't Repeat Yourself) and KISS (Keep It Simple, Stupid) principles are paramount.
* Any unimplemented code or tests must be marked with `//TODO` comment.
* Unless the requirements or user asks you to implement in phases, using TODO is prohibited. TODO means there is still unfinished work. You are required to complete your work.
* Use `pytest` for running tests and makesure this project is testable.
* Place tests in the `tests` folder; any test files located in the project root directory are considered temporary and should be deleted.
* Follow the testing principles and practices outlined in [Test Guidelines](docs/testing_guidelines.md)` if there is one.
* Always use Python's standard `logging` module for all log output.
* Always `black --line-length=100 --skip-string-normalization` and `flake8` the submitting files and fix any warnings before submitting any code. Do not lint the whole project, only the files you are submitting. Use the `.flake8` configuration file in the root directory for linting. Fix not only the errors but also styling warnings.

## Gradio UI Guidelines

* The UI is constructed using Gradio v3.41.2 and v4.40.0 but under v5.
* Components are named descriptively; abbreviations are discouraged.
* Interface layout is organized using `gr.Tabs()` and `gr.TabItem()`.
* Event bindings use `.click()`, `.change()`, `.select()`, etc.
* `gr.State()` is used for cross-component state management.
* DO NOT USE `gr.Box()` since it is deprecated.
