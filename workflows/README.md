# Workflows

This folder stores exported n8n workflows as JSON files.

## How to export a workflow from n8n

1. Open the workflow in n8n
2. Click the **⋯ menu** (top right) → **Download**
3. Save the `.json` file into this folder
4. Commit and push to GitHub

## How to import a workflow on the Jetson Nano

1. `git pull` on the Nano to get the latest workflows
2. Open n8n → click **+** → **Import from file**
3. Select the JSON file from this folder
4. Review credentials and activate

## Naming convention

```
workflows/
├── ai-companion-chat.json          # main AI chat interface
├── ai-companion-memory.json        # variant with persistent memory
├── home-automation-alerts.json
└── ...
```

Use lowercase, hyphen-separated names that describe what the workflow does.
