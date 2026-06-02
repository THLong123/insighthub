# Day 2

## Checklist

- [x] Configure `.mcp.json` with 4+ MCP servers: filesystem, docker, kubernetes, prometheus.
- [ ] Verify connected with `claude.cmd mcp list` after approving project MCP in interactive Claude Code.
- [x] Add Kubernetes read-only ServiceAccount manifest.
- [x] Add AWS `mcp-readonly` profile instructions and starter policy.
- [x] Save MCP debug session log.

## Verify Commands

```powershell
claude.cmd mcp list
kubectl apply -f infra/k8s/mcp-readonly/serviceaccount.yaml
kubectl auth can-i get pods --as=system:serviceaccount:insighthub:mcp-readonly
kubectl auth can-i delete pods --as=system:serviceaccount:insighthub:mcp-readonly
aws --profile mcp-readonly sts get-caller-identity
```
