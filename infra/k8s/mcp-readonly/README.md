# MCP Kubernetes Read-Only Access

Apply the ServiceAccount and RBAC:

```powershell
kubectl apply -f infra/k8s/mcp-readonly/serviceaccount.yaml
```

Verify read-only permissions:

```powershell
kubectl get sa mcp-readonly -n insighthub
kubectl auth can-i get pods --as=system:serviceaccount:insighthub:mcp-readonly
kubectl auth can-i delete pods --as=system:serviceaccount:insighthub:mcp-readonly
```

Expected:

```text
yes
no
```

Create `C:\Users\admin\.kube\mcp-viewer.kubeconfig` from the ServiceAccount token and cluster CA for your lab cluster. Keep that kubeconfig out of Git.
