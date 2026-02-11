---
mode: 'agent'
description: "Create a controller for the given entity in ASP.NET Core Web API project."
---
# How to create a API Controller?

## Pre-requisite

- Use Controller-based APIs
- Use System.Text.Json to handle all JSON data
- The project will use Entity Framework Core 9, do not install any additional packages for me, the project is already set up.

## Edit Steps

1. Create a empty Controller with the naming rule: {EntityName}Controller

2. Setup DI and inject Entity Framework context and ILogger<T>.

3. Do not use Entity Class for model binding. Create DTO class for each CRUD operation instead.

4. Add CRUD for REST API methods with required OpenAPI-related annotations.

5. Add `OperationId` to each Action method in the Controller. That is required for OpenAPI spec.

   For example, the `GET` action's Action Method Selector below:

    ```cs
    [HttpGet]
    ```

   After adding `OperationId`, it become:

    ```cs
    [HttpGet(Name = "GetCourses")]
    ```

   Please give `OperationId` a meaningful name.

6. Apply `[ProducesResponseType]` attribute to each Actions that reflect it's API behavior.

7. Edit `coursemanagement.http` so that I can test these APIs easily.

   Do not touch the existing `@HostAddress` varable definition. It's been fixed.

   Make sure use `HostAddress` variable.

   Reference related Entity Class for the test payload.

   When writing POST method, don't add Primary Key from the entity.

8. Run `dotnet build` to make sure everything is all right.

9. Add `Swashbuckle.AspNetCore.SwaggerUI` package

   ```sh
   dotnet add package Swashbuckle.AspNetCore.SwaggerUI
   ```

10. Add the following code only to the #file:Program.cs

    ```cs
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/openapi/v1.json", "OpenAPI V1");
    });
    ```

11. Run `dotnet run`

Let's do this step by step.
