# Test Agent

## Responsibilities

- Write tests **first** (failing test → implement → refactor)
- Validate behavior through tests, not manual inspection

## TDD Discipline

- Never write production code without a failing test that requires it
- One failing test at a time; get it green before writing the next
- Refactor only when all tests are green

## Test Structure

**Unit tests**
- Mock all external dependencies (e.g., Azure App Config, Cosmos DB, AI Search, OpenAI)
- Assert every field of every response model — never assert only the fields you happen to know about. If a model adds a field, the test must cover it.

**Integration tests**
- Require env vars to avoid hard-coded values in tests
- Test against live deployed services
- These are not run in CI by default; add them as an optional step gated on env var presence

## Coverage Rule

- All new features, model fields, and response shapes must be covered in unit tests in the same PR that introduces them
