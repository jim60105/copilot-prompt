---
# applyTo: "**/*.ts,**/*.tsx,**/*.js,**/*.html,**/*.css,**/*.scss,**/*.vue"
---
# Web Design Guidelines

## General Principles

* Keep designs simple and intuitive
* Ensure responsive layouts for all device sizes
* Maintain consistent design patterns throughout the application

## Tailwind CSS Guidelines

* Use Tailwind's utility classes for styling instead of custom CSS when possible
* For repeated components, use Tailwind's `@apply` directive in component classes
* Follow the mobile-first approach using Tailwind's responsive prefixes (`sm:`, `md:`, `lg:`, `xl:`)
* Use Tailwind's color system for consistency (`text-blue-500`, `bg-gray-100`, etc.)

## HTML Best Practices

* Use semantic HTML5 elements (`<header>`, `<nav>`, `<main>`, `<section>`, `<article>`, `<footer>`)
* Ensure proper accessibility with ARIA attributes where needed
* Keep the DOM structure clean and minimal
* Use appropriate heading hierarchy (h1-h6)

## VanillaJS Implementation

* Write modular JavaScript functions
* Minimize DOM manipulations by batching changes
* Use event delegation for better performance
* Implement progressive enhancement principles
* Prefer modern ES6+ syntax and features

## Example Component

```html
<!-- Example card component using Tailwind and VanillaJS -->
<div class="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow duration-300">
    <h3 class="text-xl font-semibold text-gray-800 mb-2">Card Title</h3>
    <p class="text-gray-600 mb-4">Card description with important information.</p>
    <button
        class="bg-blue-500 hover:bg-blue-600 text-white font-medium py-2 px-4 rounded transition-colors duration-200"
        onclick="handleClick(event)"
    >
        Action Button
    </button>
</div>

<script>
    function handleClick(event) {
        // Prevent default behavior
        event.preventDefault();

        // Example of modular functionality
        const card = event.target.closest('div');
        card.classList.add('bg-blue-50');

        // Show feedback to user
        const feedbackEl = document.createElement('p');
        feedbackEl.textContent = 'Action performed!';
        feedbackEl.className = 'text-green-600 mt-2 text-sm';
        card.appendChild(feedbackEl);
    }
</script>
```
