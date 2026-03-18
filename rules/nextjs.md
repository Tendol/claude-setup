---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "**/next.config.*"
  - "**/app/**"
  - "**/pages/**"
---

# Next.js Conventions

- Use App Router patterns (app/ directory) unless the project uses Pages Router.
- Server Components by default. Only add `"use client"` when the component needs browser APIs, hooks, or event handlers.
- Use `next/image` for images, `next/link` for navigation.
- Data fetching: use server components with `async/await` for server-side data. Use React Query or SWR for client-side.
- API routes go in `app/api/` using Route Handlers.
- Use TypeScript strict mode. Define prop types with interfaces.
- Lint with `eslint` + `next/core-web-vitals` config. Format with `prettier`.
- Use CSS Modules or Tailwind — avoid inline styles for anything reused.
- Environment variables: `NEXT_PUBLIC_*` for client, plain names for server-only.
