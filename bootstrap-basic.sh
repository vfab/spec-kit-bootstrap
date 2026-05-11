#!/bin/bash

set -e

echo "Creating agentic spec-driven repo..."

mkdir -p docs/how-to agents templates .github/instructions

# Helper: create file only if it doesn't exist
create_if_missing() {
  if [ ! -f "$1" ]; then
    echo "Creating $1"
    mkdir -p "$(dirname "$1")"
    cat > "$1"
  else
    echo "Skipping existing $1"
    cat > /dev/null
  fi
}

# Ensure uv is available
if ! command -v uv &>/dev/null; then
  echo "Error: 'uv' is required but not installed." >&2
  echo "See https://docs.astral.sh/uv/getting-started/installation/" >&2
  exit 1
fi

# Ensure spec-kit is installed and up to date
ensure_speckit() {
  if ! command -v specify &>/dev/null; then
    echo "spec-kit not found. Installing..."
    uv tool install specify-cli --from git+https://github.com/github/spec-kit.git
    echo "spec-kit installed: $(specify --version 2>/dev/null || echo 'version unknown')"
  else
    local before
    before=$(specify --version 2>/dev/null || echo "unknown")
    echo "spec-kit found ($before). Checking for updates..."
    if uv tool upgrade specify-cli; then
      local after
      after=$(specify --version 2>/dev/null || echo "unknown")
      if [ "$before" != "$after" ]; then
        echo "spec-kit upgraded: $before → $after"
      else
        echo "spec-kit is already up to date."
      fi
    else
      echo "Warning: could not check for updates. Continuing with $before."
    fi
  fi
}

ensure_speckit

# README
create_if_missing README.md << 'EOF'
# Agentic Spec-Driven Development System (with spec-kit)

## Setup

Install spec-kit if not already available:

    command -v specify &>/dev/null || uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

## Start

specify create

Then prompt:
"Use the bootstrap protocol and begin discovery"
EOF

# PROCESS
create_if_missing docs/process.md << 'EOF'
# Process

1. specify create
2. Agent discovery (Q&A)
3. specify refine
4. Architect validation
5. specify tasks
6. TDD execution
7. Review
8. Deploy
EOF

# CONSTITUTION
create_if_missing docs/constitution.md << 'EOF'
# Constitution

## Principles
- Simplicity
- Maintainability
- Security first

## Spec-Driven
- All work originates from spec-kit

## TDD
- Tests before code

## Architecture
- Layered (API → Service → Domain → Data)

## Continuous Improvement
- Propose improvements
- Do not auto-apply major changes

## Additional Context

Spec-Kit and Copilot load additional context from:
- `agents/` — agent role definitions (architect, implementation, test, reviewer, devops, product)
- `docs/how-to/` — process and tooling guides
- `docs/architecture.md` — system architecture
- `docs/process.md` — development workflow

When generating plans or specs, refer to `agents/` for role responsibilities
and `docs/how-to/` for process guidance.

> **Note:** Newer versions of spec-kit also support `.github/instructions/` for
> automatically injecting context into every Copilot interaction. If your
> spec-kit version supports it, files in `.github/instructions/*.instructions.md`
> (with `applyTo: "**"`) will be loaded for all files in the workspace.
EOF

# ARCHITECTURE
create_if_missing docs/architecture.md << 'EOF'
# Architecture

## Overview
TBD

## Layers
- API
- Service
- Domain
- Data
EOF

# ADR TEMPLATE
create_if_missing templates/adr-template.md << 'EOF'
# ADR

## Context
## Decision
## Tradeoffs
EOF

# AGENTS INDEX
create_if_missing agents/agents.md << 'EOF'
# Agents

- Architect
- Implementation
- Test
- Reviewer
- DevOps
- Product
EOF

# ARCHITECT
create_if_missing agents/architect.md << 'EOF'
# Architect Agent

- Own architecture
- Validate specs
- Create ADRs
EOF

# IMPLEMENTATION
create_if_missing agents/implementation.md << 'EOF'
# Implementation Agent

- Write code
- Follow TDD
- Follow SOLID
EOF

# TEST
create_if_missing agents/test.md << 'EOF'
# Test Agent

- Write tests first
- Validate behavior
EOF

# REVIEWER
create_if_missing agents/reviewer.md << 'EOF'
# Reviewer Agent

- Enforce standards
- Validate TDD
EOF

# DEVOPS
create_if_missing agents/devops.md << 'EOF'
# DevOps Agent

- CI/CD
- Deployment
EOF

# PRODUCT
create_if_missing agents/product.md << 'EOF'
# Product Agent

- Define requirements
- Ensure value
EOF

# HOW-TO TDD
create_if_missing docs/how-to/tdd.md << 'EOF'
# TDD

1. Write failing test
2. Implement
3. Refactor
EOF

# HOW-TO SPEC-KIT
create_if_missing docs/how-to/spec-kit.md << 'EOF'
# spec-kit

specify create
specify refine
specify tasks
EOF

# GITHUB INSTRUCTIONS — loaded by Copilot for all files.
# Spec-Kit native support for this directory requires a newer version of spec-kit.
# These files are safe to create on any version; Copilot will use them regardless.
create_if_missing .github/instructions/process.instructions.md << 'EOF'
---
applyTo: "**"
---
# Development Process

Follow this process for all work:

1. `specify create` — define the spec
2. Agent discovery (Q&A)
3. `specify refine` — iterate on the spec
4. Architect validation
5. `specify tasks` — break work into tasks
6. TDD: write failing test → implement → refactor
7. Review
8. Deploy
9. Record decisions as ADRs in `docs/decisions/`

See `docs/process.md` for full details.
EOF

create_if_missing .github/instructions/agents.instructions.md << 'EOF'
---
applyTo: "**"
---
# Agent Roles

- **Architect** — owns architecture, validates specs, creates ADRs. See `agents/architect.md`.
- **Implementation** — writes production code following TDD and SOLID. See `agents/implementation.md`.
- **Test** — writes tests first, validates behavior. See `agents/test.md`.
- **Reviewer** — enforces standards and validates TDD. See `agents/reviewer.md`.
- **DevOps** — manages CI/CD and deployment. See `agents/devops.md`.
- **Product** — defines requirements and ensures value. See `agents/product.md`.
EOF

create_if_missing .github/instructions/architecture.instructions.md << 'EOF'
---
applyTo: "**"
---
# Architecture

This project follows a layered architecture:

- **API** — entry points (REST, GraphQL, CLI)
- **Service** — business logic and orchestration
- **Domain** — core models and rules
- **Data** — persistence and external integrations

Cross-layer rules:
- Dependencies point inward only (Domain has no outward deps)
- All work originates from a spec (`specs/`)
- Key decisions recorded as ADRs in `docs/decisions/`

See `docs/architecture.md` for full details.
EOF

# Install/merge SpecKit constitution into .specify/memory/constitution.md
_BOOTSTRAP_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$_BOOTSTRAP_SCRIPT_DIR/bootstrap-constitution.sh" ]; then
  echo ""
  bash "$_BOOTSTRAP_SCRIPT_DIR/bootstrap-constitution.sh" "$PWD"
fi

echo "Done. Repo scaffold created (existing files were not modified)."