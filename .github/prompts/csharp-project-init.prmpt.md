---
mode: 'agent'
description: "Create a C# project and set up the development environment."
---
請遵循以下流程檢查並設定開發環境。

please do git commit for each step when you run command of edit files. If nothing to commit, just ignore it.

1. Make sure the Git working tree is clean with #changes and git command.

    ```ps1
    git status
    ```

   If the working directory is not clean, please stop execution.

3. Check for .NET SDK version. It must be larger than `9.0.100`.

    ```ps1
    dotnet --version
    ```

4. Use `dotnet` CLI to create project by using `webapi` template without assign `-n` argument.

    ```ps1
    dotnet new webapi -controllers
    ```

5. Add Entity Framework Core 9 and related SQL Server NuGet packages. Don't use prerelease version.

6. Check for EF Core Power Tools CLI has been installed.

    ```ps1
    efcpt --version
    ```

   If efcpt is not installed yet, or if the version is lower than `9.1.807`, please reinstall to the latest version:

    ```ps1
    dotnet tool update ErikEJ.EFCorePowerTools.Cli -g --version 9.*
    ```

7. Setup C# Global Usings in the project.

   The filename must be `GlobalUsings.cs`. Add some common namespace to it.

8. Add `.gitignore` file
   Read #gitignore-generator.prompt.md for details.

9. Add `.gitattributes` file that avoid cross-platform issues.

   Write this content to the `.gitattributes` file.

    ```gitattributes
    # Set default behavior to automatically normalize line endings.
    * text=auto

    # Force batch scripts to always use CRLF line endings so that if a repo is accessed
    # in Windows via a file share from Linux, the scripts will work.
    *.{cmd,[cC][mM][dD]} text eol=crlf
    *.{bat,[bB][aA][tT]} text eol=crlf

    # Force bash scripts to always use LF line endings so that if a repo is accessed
    # in Unix via a file share from Windows, the scripts will work.
    *.sh text eol=lf
    
    .env text eol=lf
    Dockerfile text eol=lf

    # Denote all files that are truly binary and should not be modified.
    *.mp3 binary
    *.wav binary
    *.bmp binary
    *.png binary
    *.jpg binary
    *.gif binary
    ```

10. Download the .editorconfig with this command

curl -sL https://gist.github.com/jim60105/ae6ba63978a2dc3ffb3ebb77344cc7f7/raw/47f342c4b793a32697af6d62022692c26f849c07/.editorconfig > .editorconfig

Let's do this step by step.
