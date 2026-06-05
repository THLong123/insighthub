# AWS MCP Read-Only Profile

Create or configure a dedicated AWS profile named `mcp-readonly`.

Recommended managed policy for lab use:

```powershell
aws iam attach-user-policy `
  --user-name mcp-readonly `
  --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess
```

More restrictive starter policy:

```powershell
aws iam put-user-policy `
  --user-name mcp-readonly `
  --policy-name InsightHubMcpReadOnly `
  --policy-document file://infra/aws/mcp-readonly-policy.json
```

Configure local credentials:

```powershell
aws configure --profile mcp-readonly
aws --profile mcp-readonly sts get-caller-identity
```

The `.mcp.json` AWS server uses:

```json
{
  "AWS_PROFILE": "mcp-readonly"
}
```

Do not use an admin profile for MCP.
