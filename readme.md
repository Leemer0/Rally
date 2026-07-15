# Rally

Rally is a mobile-first nightlife discovery app for deciding where to go based on
aggregated social momentum. The product is being built as a Next.js web MVP around a
versioned API that can later support a separate SwiftUI client.

## Local development

```bash
npm install
cp .env.example .env.local
npm run dev
```

The current phase establishes the design system and adaptive application shell. Open
`http://localhost:3000` to view the component lab.

## Quality checks

```bash
npm run format:check
npm run lint
npm run typecheck
npm run test
npm run test:e2e
npm run build
```

## Architecture boundaries

- `contracts/` — public OpenAPI contract and portable examples
- `src/contracts/` — client-safe DTOs and schemas
- `src/api-client/` — typed access to `/api/v1`
- `src/domain/` — framework-independent business rules
- `src/server/` — server-only orchestration and persistence
- `src/components/` — presentation components; never direct database access

Application routes will live under `/api/v1` and use a consistent data/error envelope.
