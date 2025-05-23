---
mode: 'agent'
description: "Initialize EF Core DbContext for the project."
tools:
  - codebase
  - changes
---
## Pre-requisite

1. Make sure the working tree is clean with #changes and git command.

    ```ps1
    git status
    ```

   If the working directory is not clean, please stop execution.

## Steps

1. Use EF Core Power Tools CLI to generate required.

    ```ps1
    efcpt "Server=(localdb)\MSSQLLocalDB;Initial Catalog=ContosoUniversity;Trusted_Connection=True;Encrypt=false" mssql
    ```
   (Note: This is the connection string of MSSQL. You should use the correct ConnectionString according to the project requirements.)

2. Run `dotnet build` to make sure everything is all right.

3. Configure `Program.cs` for DI and configure `appsettings.json` for connection strings. Reference from `efcpt-readme.md` file for instructions. Make sure using necessary namespaces.

4. Run `dotnet build` to make sure everything is all right.

Let's do this step by step.
