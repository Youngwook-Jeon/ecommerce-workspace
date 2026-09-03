# Repository Guide

This workspace combines a Spring Boot MSA backend, a Next.js frontend, and local orchestration scripts.

## Layout

- `ecommerce-msa/`: Java 21, Spring Boot 3.5, Maven multi-module backend.
  - `edge-service`: Gateway, Keycloak OAuth2 login, Redis-backed session, SPA proxy (`:9000`).
  - `product-service`, `order-service`, `payment-service`: Hexagonal modules split into domain, data access, web, messaging, and executable `*-service-main` modules.
  - `customer-service`: Skeleton; not started or routed by the default stack.
  - `common-library`, `infra/kafka`: Shared domain/application code and Kafka configuration/models.
  - `deployment/docker/`: PostgreSQL, Redis, Keycloak, Kafka, Schema Registry, Kafka Connect/Debezium, and Kafka UI.
- `ecommerce-frontend/`: Next.js 15 App Router, React 19, TypeScript, Tailwind; Bun is the package manager.
- `Makefile`, `scripts/`: Workspace-level build and local lifecycle orchestration.

## Commands

Run workspace commands from the repository root:

- `make up` / `make down`: Start or stop infrastructure and backend services.
- `make build`: Maven install with tests skipped.
- `cd ecommerce-msa && ./mvnw clean verify`: Full backend build and test suite.
- `cd ecommerce-msa && ./mvnw -pl product-service/product-service-main -am test`: Test one backend module and its required reactor dependencies. Replace the `-pl` path with the module being changed.
- `cd ecommerce-msa && ./mvnw -pl product-service/product-service-main -am -Dtest=ProductApiIntegrationTest -Dsurefire.failIfNoSpecifiedTests=false test`: Run one backend test class. The extra Surefire flag prevents dependency modules without that class from failing the reactor build.
- `cd ecommerce-msa && ./mvnw -pl product-service/product-service-main -am "-Dtest=ProductApiIntegrationTest#methodName" -Dsurefire.failIfNoSpecifiedTests=false test`: Run one test method.
- `make frontend`: Install frontend dependencies and run the Next.js dev server.
- `cd ecommerce-frontend && bun run build`: Production frontend build.
- `cd ecommerce-frontend && bun run lint`: Frontend lint. No automated frontend test suite is configured.

Prefer the narrowest relevant Maven module or frontend check while iterating, then run broader verification when the change crosses module boundaries.

## Architecture and Integration

- Browser traffic enters through `http://localhost:9000`; the Gateway proxies non-API routes to Next.js on `:3000`.
- Frontend services call Gateway paths under `/api/v1/{product_service|order_service|payment_service}/...`.
- Preserve the frontend `fetchWrapper` behavior: forward the Gateway session cookie and CSRF token for authenticated requests. Public reads use the cookie-free public fetch helper.
- Image binaries use backend-issued presigned URLs and upload directly to R2 without session cookies.
- Order calls Product synchronously for catalog/inventory operations. Order and Payment coordinate asynchronously through Debezium outbox events and Kafka.
- Keep domain code independent of web, persistence, messaging, and provider-specific adapters.

## Coding Conventions

### Backend

- Follow the existing Java style: four-space indentation, explicit imports, one public top-level type per file, and names that describe the domain responsibility.
- Keep package and dependency direction aligned with the hexagonal structure: `web` and `messaging` are inbound/outbound adapters, `dataaccess` implements persistence ports, `application` owns use cases and ports, and `domain-core` contains framework-independent business rules.
- Prefer constructor injection; avoid field injection and avoid introducing Spring, JPA, Kafka, or provider-specific types into `domain-core`.
- Use command/query DTOs and port interfaces at layer boundaries. Keep HTTP DTO mapping in `web` and entity/domain mapping in `dataaccess`.
- Put transaction boundaries at the existing application or adapter boundary, not inside domain entities. Preserve outbox writes when changing event-driven flows.
- Name unit/integration tests `*Test`; use JUnit 5 and the existing AssertJ/Mockito/Testcontainers patterns. Add tests in the module that owns the behavior.

### Frontend

- Follow the existing TypeScript style: strict typing, two-space indentation, semicolons, double quotes, and `@/` path aliases for cross-directory imports.
- Use App Router Server Components by default. Add `"use client"` only for browser APIs, state, effects, or interactive UI; keep mutations and cookie-aware backend calls in server actions/services where practical.
- Keep route files in `src/app`, feature UI and logic in `src/modules`, shared primitives in `src/components/ui` or `src/common`, and backend access in `src/services`/`src/common/services`.
- Use PascalCase for components and types, camelCase for functions and variables, and `useXxx` for hooks. Keep components focused and colocate feature-specific helpers with their module.
- Validate external/API data with the existing Zod schemas and preserve typed view models. Route authenticated calls through `fetchWrapper` and anonymous cacheable reads through `publicGet`.
- Reuse the existing shadcn/Radix components, Tailwind utilities, CSS variables, and `cn` helper instead of adding parallel styling systems. Follow `next/core-web-vitals` and `next/typescript` lint rules.

## Local Configuration

- Create `ecommerce-msa/.env` from `.env.example`; the default local stack uses `R2_ENABLED=false` and `PAYMENT_PROVIDER=stub`.
- Stripe requires backend `STRIPE_API_KEY` and frontend `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY`; the local scripts normally inject the webhook secret through Stripe CLI.
- R2 credentials are required only when `R2_ENABLED=true`.
- Never commit or print secrets from `.env` or `.env.local`.

## Working Rules

- Do not edit generated/runtime directories such as `target/`, `node_modules/`, `.next/`, `.run/`, or local Maven caches.
- Preserve unrelated user changes and keep edits scoped to the requested component.
- Update configuration, tests, and documentation together when changing API routes, environment variables, ports, or event topics.
- Use the existing Maven wrapper, Bun lockfile, Make targets, and repository conventions; do not introduce a second build or package-management path.
