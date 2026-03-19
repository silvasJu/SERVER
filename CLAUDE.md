# CLAUDE.md — AI Assistant Guide for silvasJu/SERVER

## Repository Overview

This is an **n8n Workflow Backup Repository** — not a traditional software development project. It contains JSON exports of n8n automation workflows that are automatically committed by n8n's built-in Git backup feature.

**What n8n is:** A self-hosted workflow automation platform (like Zapier/Make) where you build automations visually by connecting nodes. Each workflow is stored as a JSON file describing its nodes, connections, and settings.

---

## Directory Structure

```
SERVER/
├── CLAUDE.md                          # This file
└── workflows/                         # All n8n workflow JSON exports
    ├── *.json                         # ~30 workflow files (root level)
    ├── 1 (0/...)/                     # Versioned copy: AVIA_Main
    ├── 1 (1/...)/                     # Versioned copy: AVIA_Cuadro
    ├── 1 (2/...)/                     # Versioned copy: AVIA_Prescripciones
    └── 1 (3/...)/                     # Versioned copy: AVIA_Condiciones
```

There are **no source code files, no build system, no tests, no CI/CD** — everything is workflow JSON.

---

## Workflow JSON Schema

Every file under `workflows/` follows this n8n export structure:

```json
{
  "active": false,          // true = workflow is enabled and will trigger
  "connections": { },       // Maps node outputs to node inputs
  "nodes": [ ],             // Array of node definitions (see below)
  "name": "Workflow Name",
  "id": "unique_id",
  "settings": {
    "executionOrder": "v1"
  },
  "tags": [],
  "triggerCount": 0,        // Execution count
  "createdAt": "ISO date",
  "updatedAt": "ISO date",
  "versionId": "guid",
  "shared": []
}
```

### Node Structure

```json
{
  "id": "node-uuid",
  "name": "Node Display Name",
  "type": "n8n-nodes-base.httpRequest",  // Node type identifier
  "typeVersion": 4,
  "position": [x, y],                    // Visual canvas position
  "parameters": { }                       // Node-specific configuration
}
```

---

## Workflow Catalog

### Active Workflows (running in production)
| File | Purpose |
|------|---------|
| `My workflow.json` | Instagram webhook receiver |
| `Backup Github.json` | Automated GitHub backup (this repository) |

### AVIA Series (Procurement/Tender Analysis)
Spanish-language workflows for analyzing public procurement tenders:
| File | Role |
|------|------|
| `AVIA_Main.json` / `4 AVIA_Main.json` | Orchestrator — coordinates the other AVIA workflows |
| `AVIA_Cuadro.json` / `1 (1/...)/` | Builds comparison tables from tender documents |
| `AVIA_Prescripciones.json` / `1 (2/...)/` | Extracts prescriptions/requirements |
| `AVIA_Condiciones.json` / `1 (3/...)/` | Extracts conditions from tenders |
| `Licitaciones.json` | Tender ingestion/processing |

The subdirectories `1 (0/3)/`, `1 (1/3)/`, etc. contain saved versions of the AVIA workflows.

### Web Scraping & AI
| File | Purpose |
|------|---------|
| `Universal Web Scraper (Products -> 1 JSON) [Telegram].json` | Scrapes product data, outputs JSON, notifies via Telegram |
| `Web Scraping con IA - Workflow Funcional.json` | AI-assisted web scraping |

### Instagram Integration
| File | Purpose |
|------|---------|
| `ORGANIZADOR-MD-IG (PLANTILLA 1).json` | Instagram content organizer template |
| `ORGANIZADOR-MD-IG (PRUEBA 1).json` | Instagram content organizer test variant |
| `CLICK AIRTABLE-IG` (multiple) | Instagram ↔ Airtable sync workflows |

### Infrastructure & Maintenance
| File | Purpose |
|------|---------|
| `Backup all n8n workflows to Google Drive every 4 hours.json` | Google Drive backup |
| `ACTIVAR TUNNEL.json` | Cloudflare Tunnel control via Telegram |
| `Ingesta de nodos en Airtable.json` | Node catalog ingestion into Airtable |
| `Formas de pago.json` | Payment methods handling |

---

## Common n8n Node Types in This Repo

| Node Type | Description |
|-----------|-------------|
| `n8n-nodes-base.webhook` | HTTP webhook trigger |
| `n8n-nodes-base.httpRequest` | Make HTTP API calls |
| `n8n-nodes-base.code` | Run JavaScript code |
| `n8n-nodes-base.scheduleTrigger` | Time-based trigger |
| `n8n-nodes-base.merge` | Merge multiple data streams |
| `n8n-nodes-base.switch` | Conditional branching |
| `n8n-nodes-base.splitInBatches` | Process data in chunks |
| `n8n-nodes-base.aggregate` | Aggregate data |
| `n8n-nodes-base.limit` | Limit number of items |
| `n8n-nodes-base.extractFromFile` | Parse files (PDF, Excel, etc.) |
| `n8n-nodes-base.telegram` | Send Telegram messages |
| `n8n-nodes-base.airtable` | Read/write Airtable |
| `n8n-nodes-base.github` | GitHub operations |
| `@n8n/n8n-nodes-langchain.chatTrigger` | LangChain chat trigger |
| `@n8n/n8n-nodes-langchain.lmChatOpenAi` | OpenAI LLM node |
| `@n8n/n8n-nodes-langchain.agent` | LangChain AI agent |

---

## Git Workflow

### Automated Commits
This repository is updated automatically by n8n's Git backup feature. Commits appear as:
```
[n8n backup]
```
These are machine-generated — the n8n instance pushes changes whenever workflows are modified.

### Branch Strategy
- `main` — production-tracked workflows (auto-pushed by n8n)
- `master` — local default branch
- `claude/...` — branches used by AI assistants for documentation/changes

### Making Manual Changes
When editing workflow files manually:
1. Work on a feature branch (never directly on `main`)
2. Edit the JSON carefully — invalid JSON will break n8n imports
3. Validate JSON before committing: `python3 -m json.tool workflows/MyWorkflow.json`
4. Use descriptive commit messages explaining what changed in the workflow logic

---

## Key Conventions

### Naming
- Workflows follow **Spanish naming** with descriptive titles
- Series workflows use numbered prefixes: `1 AVIA_...`, `2 AVIA_...`
- Versioned copies use parenthetical notation: `1 (0/3)/`, `1 (1/3)/`
- Test/template variants use suffixes: `(PLANTILLA 1)`, `(PRUEBA 1)`

### Workflow Design Patterns
- **Orchestrator pattern:** `AVIA_Main` calls sub-workflows (AVIA_Cuadro, AVIA_Prescripciones, AVIA_Condiciones)
- **Telegram as UI:** Many workflows use Telegram for input and output (user-friendly interface)
- **Airtable as database:** Primary data store for structured records
- **AI nodes:** OpenAI/LangChain used for document analysis and content generation

---

## What AI Assistants Should Know

### Do's
- When asked to modify a workflow, edit the JSON directly while preserving the schema structure
- Validate that `connections` references match existing node `id` values
- Keep `updatedAt` timestamps consistent if touching metadata
- Respect the Spanish-language naming convention for new workflows
- Use `position` coordinates that make sense on the visual canvas (spread nodes out, e.g., 200px apart)

### Don'ts
- Don't create build files, package.json, or development tooling — this is not a code project
- Don't add node types not already used unless the user explicitly requests new integrations
- Don't change `id` or `versionId` fields on existing workflows — these are used by n8n for tracking
- Don't set `"active": true` unless explicitly asked — activating workflows in the JSON could cause them to trigger unexpectedly when imported

### When Asked to Add a New Workflow
Create a new `.json` file in `workflows/` following the schema above. Minimum required fields:
```json
{
  "name": "Workflow Name",
  "nodes": [],
  "connections": {},
  "active": false,
  "settings": { "executionOrder": "v1" },
  "id": "",
  "tags": []
}
```

---

## Remote & Access

- **Git remote:** `http://local_proxy@127.0.0.1:37421/git/silvasJu/SERVER`
- **n8n instance:** Self-hosted (local or tunneled via Cloudflare — see `ACTIVAR TUNNEL.json`)
- **Primary language:** Spanish (workflows and content)
- **Integrations used:** Telegram, Airtable, GitHub, Google Drive, OpenAI, Instagram, Cloudflare
