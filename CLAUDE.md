# CLAUDE.md — SERVER Repository

## What This Repo Is

This is an **n8n workflow backup repository**. The n8n instance automatically exports its workflow definitions as JSON files and commits them here via the "Backup Github" workflow. There is no traditional build process — the repository is a versioned snapshot of automation workflows.

---

## Repository Structure

```
SERVER/
└── workflows/          # All n8n workflow definitions (JSON)
```

Each file in `workflows/` is a complete n8n workflow exported as JSON. File names are descriptive (mix of Spanish and English). Numbered prefixes (1, 2, 3, 4) indicate execution order within a family of related workflows.

### Workflow Families

| Prefix / Name | Purpose |
|---|---|
| `1 AVIA_*`, `2 AVIA_*`, `3 AVIA_*`, `4 AVIA_*` | AVIA contract/procurement analysis pipeline (ordered sub-workflows) |
| `AV - *` | AV engineering/document analysis workflows |
| `AVIA-Pro *` | Tender analysis with Bill of Materials generation |
| `Universal Web Scraper *` | Web scraping → structured JSON via AI |
| `Chatbot Salud *` | Healthcare chatbot on Telegram |
| `Licitaciones` | Public procurement document analysis |
| `Backup Github` | **Active** — automated backup scheduler (this repo's CI) |
| `ORGANIZADOR-MD-IG`, `Md-INSTAGRAM` | Markdown content → Instagram publishing |
| `QSYS *` | Automatic configuration generator |

---

## Technology Stack

- **Platform:** n8n (workflow automation)
- **AI/LLM:** OpenAI via LangChain nodes, Google Gemini
- **Integrations:** Airtable, Telegram, Google Drive, GitHub, Shopify, PayPal, ScrapeNinja
- **In-workflow code:** JavaScript (inside `n8n-nodes-base.code` nodes)

---

## Workflow JSON Structure

Every workflow file follows this schema:

```json
{
  "name": "Workflow Name",
  "active": true | false,
  "id": "unique-id",
  "createdAt": "ISO-8601",
  "updatedAt": "ISO-8601",
  "nodes": [ ... ],        // Execution steps
  "connections": { ... },  // Data flow between nodes
  "settings": { "executionOrder": "v1" },
  "meta": { "templateCredsSetupCompleted": true },
  "tags": [],
  "triggerCount": 0,
  "pinData": {},
  "staticData": null
}
```

**Active workflows:** Only `Backup Github.json` is active (`"active": true`). All others are inactive/archived.

---

## Common Node Types

| Node type | Role |
|---|---|
| `n8n-nodes-base.code` | JavaScript transformation/logic |
| `n8n-nodes-base.airtable` | Read/write Airtable tables |
| `@n8n/n8n-nodes-langchain.openAi` | LLM calls (OpenAI) |
| `n8n-nodes-base.httpRequest` | External HTTP/API calls |
| `n8n-nodes-base.webhook` | Incoming HTTP triggers |
| `n8n-nodes-base.extractFromFile` | Parse PDF / document files |
| `@n8n/n8n-nodes-langchain.agent` | LangChain AI agents |
| `n8n-nodes-base.telegram` | Send Telegram messages |
| `n8n-nodes-base.merge` / `switch` / `if` | Flow control |

### Trigger Patterns

- `manualTrigger` — run from n8n UI
- `scheduleTrigger` — cron-based execution
- `webhook` — HTTP POST endpoint
- `executeWorkflowTrigger` — called as a sub-workflow
- `telegramTrigger` / `chatTrigger` — conversational interfaces
- `googleDriveTrigger` — fires on Drive file changes

---

## Data Flow Pattern

Most workflows follow this pattern:

```
Trigger → Code (JS transform) → AI/LLM → Storage (Airtable / Drive) → Output (Telegram / Webhook response)
```

---

## Credentials & Secrets

- **No secrets are stored in this repo.** Workflow JSON files reference credential type identifiers only (e.g., `"telegramApi"`, `"openaiApi"`).
- Actual API keys are managed inside the n8n instance's encrypted credential store.
- Never commit real credentials to this repository.

---

## Git & Backup Conventions

- **Backup commits** are generated automatically by the `Backup Github` workflow with messages like:
  `[n8n backup] <WorkflowName>.json (different)`
- **Human commits** should be descriptive and use the same repo language convention (English or Spanish is fine).
- Always develop on a feature branch; `main` tracks the live n8n state.
- There are no automated tests — n8n provides built-in execution testing in the UI.

---

## How to Import a Workflow

1. Open your n8n instance.
2. Go to **Workflows → Import from File**.
3. Select the JSON file from `workflows/`.
4. Configure credentials in the workflow nodes before activating.

---

## Naming Conventions

- Workflow files: descriptive names in Spanish or English, spaces allowed (JSON filenames match n8n workflow names).
- Numbered prefixes (`1 `, `2 `, etc.) denote ordered sub-workflows in a pipeline — maintain this order when working on AVIA or AV families.
- Node names inside JSON: descriptive English phrases (e.g., `"Code in JavaScript"`, `"Extract from File"`).

---

## Key Workflows to Understand First

1. **`Backup Github.json`** — understand this before touching anything; it is the only active workflow and drives all commits to this repo.
2. **`4 AVIA_Main.json`** — entry point of the AVIA procurement analysis pipeline.
3. **`Universal Web Scraper (Products -> 1 JSON) [Telegram].json`** — most frequently modified workflow; good example of the scraping + AI pattern.
4. **`AV - Ingesta y análisis de pliegos (IA).json`** — document ingestion pipeline, second most frequently modified.
