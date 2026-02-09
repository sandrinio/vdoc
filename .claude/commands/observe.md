# Observability Skill

Help users debug and monitor AI workflows by accessing historical execution logs and detailed tracing data.

**Usage:** `/observe $ARGUMENTS`

The `$ARGUMENTS` variable contains the query or execution ID to investigate.

## Capabilities

1. **List Recent Executions**: Find recent execution IDs for a specific project.
2. **Inspect Execution Details**: Get status, timing, and AI usage for an execution.
3. **Summarize Traces**: Explain the step-by-step logic and tool usage of an agent's run.

## Workflow Patterns

### Pattern 1: "Show me the last execution"
```bash
curl http://localhost:8000/observability/projects/{project_id}/recent?limit=1
```
- Use the returned `id` to fetch full details
- Summarize the status and duration

### Pattern 2: "Why did it fail?"
```bash
curl http://localhost:8000/observability/executions/{execution_id}
```
- Examine the `trace` for the first span containing an `exception_type` or failed tool call
- Report the specific error message and the context (inputs/tools) leading up to it

### Pattern 3: "How many tokens did we use?"
```bash
curl http://localhost:8000/observability/executions/{execution_id}
```
- Sum the `total_tokens` from `ai_usage`
- Present in a table format

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /observability/projects/{project_id}/recent` | List recent executions |
| `GET /observability/executions/{execution_id}` | Get execution details |

## Response Guidelines

- Always provide the `execution_id` and `session_id` in responses so users can cross-reference in Logfire
- If a trace is long, focus on the most relevant spans (tool calls and results)
- Use tables for token usage and KPI breakdowns

## Output Format

```
🔍 **Execution Summary:**
- **ID:** `{execution_id}`
- **Session:** `{session_id}`
- **Status:** ✅ Success / ❌ Failed
- **Duration:** X.Xs
- **Tokens:** {total_tokens}

📊 **Token Breakdown:**
| Model | Input | Output | Total |
|-------|-------|--------|-------|
| ... | ... | ... | ... |

🔗 **Logfire:** [View in Logfire](https://logfire.pydantic.dev/...)
```
