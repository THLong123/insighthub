# InsightHub Day 6 Threat Model

## Scope

InsightHub is a RAG application with document ingestion, vector retrieval, LLM generation, observability, and a ChatOps bot. Day 6 focuses on LLM security, governance, and FinOps controls.

## Assets

| Asset | Why It Matters | Owner |
|---|---|---|
| Uploaded documents | May contain business knowledge, PII, or poisoned instructions | App team |
| Vector store | Retrieval source for RAG answers; poisoning changes model behavior | Platform team |
| LLM API keys | Permit paid model calls and possible data exposure | Security team |
| ChatOps bot token | Allows Slack posting and operational workflow access | Platform team |
| Kubernetes access | Can impact workloads if tools are over-permissioned | SRE team |
| Audit logs | Evidence for incident review and governance | Security team |

## Threats And Controls

| ID | Threat | OWASP Link | Attack Path | Impact | Controls |
|---|---|---|---|---|---|
| T1 | Direct prompt injection | LLM01 | User asks the model to ignore the system prompt | Ungrounded or unsafe answer | Prompt hardening, Promptfoo tests |
| T2 | Indirect prompt injection | LLM01 | Uploaded document contains hidden instructions retrieved into context | Model follows malicious document text | Context marked untrusted, sanitizer, guardrail |
| T3 | Sensitive information disclosure | LLM02 | User asks for secrets, API keys, or full hidden prompts | Data leakage | Guardrail filters, deny-list sanitizer, no secret logging |
| T4 | Improper output handling | LLM05 | LLM output is treated as executable command or trusted HTML | Command or content injection | Deterministic allowlist and human review for actions |
| T5 | Excessive agency | LLM06 | ChatOps or future agent has broad tools and follows malicious goal | Unauthorized operational action | READ/WRITE/DESTRUCTIVE tiers, deny destructive actions |
| T6 | RAG poisoning | LLM08 | Malicious document is ingested and ranked highly | Persistent answer manipulation | Red-team scans, source citation, ingestion review |
| T7 | Cost runaway | FinOps | Agent loop or large prompt causes repeated expensive LLM calls | Bill shock | Token dashboard, LiteLLM routing, budget alert |
| T8 | Audit evasion | Governance | Tool calls or model decisions are not recorded | No incident evidence | NDJSON audit log, searchable security reviews |

## Residual Risk

Prompt injection cannot be eliminated by one control. InsightHub uses defense in depth: prompt hardening, context sanitization, guardrails, least privilege, audit logs, and recurring red-team scans. Production rollout should add a real LLM gateway, centralized log retention, and budget alerts in the provider console.
