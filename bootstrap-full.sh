#!/bin/bash
set -e

echo "🔄 Upgrading project to FULL agentic system..."

# Helper: create file only if it doesn't exist
create_if_missing () {
  if [ ! -f "$1" ]; then
    echo "Creating $1"
    mkdir -p "$(dirname "$1")"
    cat > "$1" << EOF
$2
EOF
  else
    echo "Skipping existing $1"
  fi
}

# Helper: upgrade file with backup
upgrade_file () {
  if [ -f "$1" ]; then
    echo "Upgrading $1 (backup created)"
    cp "$1" "$1.bak"
  else
    echo "Creating $1"
  fi

  mkdir -p "$(dirname "$1")"
  cat > "$1" << EOF
$2
EOF
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

########################################
# DIRECTORIES
########################################
mkdir -p docs/how-to agents templates .github/instructions

########################################
# README (upgrade)
########################################
upgrade_file "README.md" "# Agentic Spec-Driven Development System (Full)

This project uses:
- spec-kit for specs
- agent system for implementation

Specs define WHAT to build.
Agents define HOW to build it correctly.
"

########################################
# PROCESS (upgrade)
########################################
upgrade_file "docs/process.md" "# Development Process

1. specify create
2. Agent discovery (Q&A)
3. specify refine
4. Architect validation
5. specify tasks
6. TDD execution
7. Review
8. Deploy
9. ADR tracking
"

########################################
# CONSTITUTION (upgrade)
########################################
upgrade_file "docs/constitution.md" "# Engineering Constitution

- SOLID
- Clean Architecture
- TDD required
- Feature flags recommended
- Semantic versioning required
- Continuous improvement enforced

## Additional Context

Spec-Kit and Copilot load additional context from:
- \`agents/\` — agent role definitions (architect, implementation, test, reviewer, devops, product)
- \`docs/how-to/\` — process and tooling guides
- \`docs/architecture.md\` — system architecture
- \`docs/process.md\` — development workflow

When generating plans or specs, refer to \`agents/\` for role responsibilities
and \`docs/how-to/\` for process guidance.

> **Note:** Newer versions of spec-kit also support \`.github/instructions/\` for
> automatically injecting context into every Copilot interaction. If your
> spec-kit version supports it, files in \`.github/instructions/*.instructions.md\`
> (with \`applyTo: \"**\"\`) will be loaded for all files in the workspace.
"

########################################
# ARCHITECTURE (create if missing)
########################################
create_if_missing "docs/architecture.md" "# Architecture

## Overview
TBD
"

########################################
# ADR TEMPLATE
########################################
create_if_missing "templates/adr-template.md" "# ADR

## Context
## Decision
## Tradeoffs
"

########################################
# AGENTS
########################################
create_if_missing "agents/agents.md" "# Agents

Architect, Implementation, Test, Reviewer, DevOps, Product
"

create_if_missing "agents/architect.md" "# Architect Agent
Own architecture and validate specs
"

create_if_missing "agents/implementation.md" "# Implementation Agent
Write code following TDD
"

create_if_missing "agents/test.md" "# Test Agent
Write tests first
"

create_if_missing "agents/reviewer.md" "# Reviewer Agent
Enforce quality
"

create_if_missing "agents/devops.md" "# DevOps Agent
CI/CD and deployment
"

create_if_missing "agents/product.md" "# Product Agent
Define requirements
"

########################################
# HOW-TO DOCS
########################################
create_if_missing "docs/how-to/tdd.md" "# TDD
Write tests first
"

create_if_missing "docs/how-to/feature-flags.md" "# Feature Flags
Toggle features safely
"

create_if_missing "docs/how-to/spec-kit.md" "# spec-kit
specify create → refine → tasks
"

create_if_missing "docs/how-to/alm-tools.md" "# ALM
Track work items
"

########################################
# GITHUB INSTRUCTIONS — loaded by Copilot for all files.
# Spec-Kit native support for this directory requires a newer version of spec-kit.
# These files are safe to create on any version; Copilot will use them regardless.
########################################
create_if_missing ".github/instructions/process.instructions.md" "---
applyTo: \"**\"
---
# Development Process

Follow this process for all work:

1. \`specify create\` — define the spec
2. Agent discovery (Q&A)
3. \`specify refine\` — iterate on the spec
4. Architect validation
5. \`specify tasks\` — break work into tasks
6. TDD: write failing test → implement → refactor
7. Review
8. Deploy
9. Record decisions as ADRs in \`docs/decisions/\`

See \`docs/process.md\` for full details.
"

create_if_missing ".github/instructions/agents.instructions.md" "---
applyTo: \"**\"
---
# Agent Roles

- **Architect** — owns architecture, validates specs, creates ADRs. See \`agents/architect.md\`.
- **Implementation** — writes production code following TDD and SOLID. See \`agents/implementation.md\`.
- **Test** — writes tests first, validates behavior. See \`agents/test.md\`.
- **Reviewer** — enforces standards and validates TDD. See \`agents/reviewer.md\`.
- **DevOps** — manages CI/CD and deployment. See \`agents/devops.md\`.
- **Product** — defines requirements and ensures value. See \`agents/product.md\`.
"

create_if_missing ".github/instructions/architecture.instructions.md" "---
applyTo: \"**\"
---
# Architecture

This project follows a layered architecture:

- **API** — entry points (REST, GraphQL, CLI)
- **Service** — business logic and orchestration
- **Domain** — core models and rules
- **Data** — persistence and external integrations

Cross-layer rules:
- Dependencies point inward only (Domain has no outward deps)
- All work originates from a spec (\`specs/\`)
- Key decisions recorded as ADRs in \`docs/decisions/\`

See \`docs/architecture.md\` for full details.
"

# Install/merge SpecKit constitution into .specify/memory/constitution.md
_BOOTSTRAP_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$_BOOTSTRAP_SCRIPT_DIR/bootstrap-constitution.sh" ]; then
  echo ""
  bash "$_BOOTSTRAP_SCRIPT_DIR/bootstrap-constitution.sh" "$PWD"
fi

echo "✅ Upgrade complete!"