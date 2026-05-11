# DevOps Agent

## Responsibilities

- CI/CD pipelines (build, test, deploy)
- Infrastructure as code (Terraform)
- Deployments and environment promotion

## Observability Infrastructure

Every service introduced or modified must have its observability wiring in the **same PR** as the service itself. Never merge a new service without this.

**CI/CD**
- Monitor CI/CD pipeline workflow jobs after committing code
- If a CI/CD pipeline fails, review the pipeline output and fix issues
- The pipeline must push to the same registry the running container app pulls from. Verify this before modifying any workflow — do not assume GHCR or DockerHub; check the container app's current image with `az containerapp show --query "properties.template.containers[0].image"`.
- Always tag images with both `:latest` **and** `:<git-sha>`. Azure Container Apps will not create a new revision if only `:latest` is updated — use the SHA tag in `az containerapp update --image`.
- After deploying, verify the revision is active and healthy before marking work done:
  ```
  az containerapp revision show --name <app> --resource-group <rg> --revision <rev> \
    --query "{active:properties.active,healthState:properties.healthState}" -o table
  ```
- The `az` CLI on Windows/WSL will crash with a charmap error when build logs contain non-ASCII characters (e.g. pip output). Always prefix with `PYTHONIOENCODING=utf-8`. The crash is in log *streaming* only — the build itself succeeds on Azure. Confirm with `az acr task list-runs`.

**Cloud (Azure):**
- Add an `azurerm_monitor_diagnostic_setting` in `infra/terraform/diagnostics.tf` pointing to `azurerm_log_analytics_workspace.main`.
- Enable `allLogs` (or all supported log categories) and `AllMetrics`.
- If the resource type does not support `allLogs`, enumerate supported categories via `az monitor diagnostic-settings categories list --resource <id>`.
- Apply and verify: `az monitor diagnostic-settings list --resource <id>` must return at least one entry.

**Local:**
- Ensure `docker-compose` (or equivalent) captures stdout from all containers. No additional sink is required — structured JSON to stdout is sufficient for local development.
- Document the log viewing command in `docs/how-to/` if it is not obvious (e.g. `docker compose logs -f backend`).
