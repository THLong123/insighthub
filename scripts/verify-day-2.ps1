param(
    [string]$McpConfig = ".mcp.json"
)

$ErrorActionPreference = "Stop"
$pass = 0
$fail = 0
$warn = 0

function Pass($Message) {
    $script:pass++
    Write-Host "[PASS] $Message" -ForegroundColor Green
}

function Fail($Message) {
    $script:fail++
    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Warn($Message) {
    $script:warn++
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

Write-Host "InsightHub Day 2 MCP verification"
Write-Host ""

if (-not (Test-Path $McpConfig)) {
    Fail "$McpConfig not found"
} else {
    try {
        $config = Get-Content $McpConfig -Raw | ConvertFrom-Json
        Pass "$McpConfig is valid JSON"

        $servers = @($config.mcpServers.PSObject.Properties)
        if ($servers.Count -ge 4) {
            Pass "$McpConfig has $($servers.Count) MCP servers"
        } else {
            Fail "$McpConfig has $($servers.Count) MCP servers; expected at least 4"
        }

        $serialized = $config | ConvertTo-Json -Depth 20
        if ($serialized -match "@latest|@main") {
            Fail "MCP server version is not pinned"
        } else {
            Pass "MCP server versions are pinned"
        }

        $fsArgs = @($config.mcpServers.filesystem.args)
        if ($fsArgs -contains "/" -or $fsArgs -contains '$HOME' -or $fsArgs -contains "C:\Users\admin") {
            Fail "Filesystem MCP allow-list is too broad"
        } else {
            Pass "Filesystem MCP allow-list is scoped to project path"
        }
    }
    catch {
        Fail "$McpConfig is not valid JSON: $($_.Exception.Message)"
    }
}

if (Test-Path "infra/k8s/mcp-readonly/serviceaccount.yaml") {
    Pass "K8s read-only ServiceAccount manifest exists"
} else {
    Fail "K8s read-only ServiceAccount manifest missing"
}

if ((Test-Path "infra/aws/mcp-readonly.md") -and (Test-Path "infra/aws/mcp-readonly-policy.json")) {
    Pass "AWS mcp-readonly profile docs and starter policy exist"
} else {
    Fail "AWS mcp-readonly docs or policy missing"
}

if (Test-Path "docs/debug-session-day2.md") {
    Pass "MCP debug session log exists"
} else {
    Fail "docs/debug-session-day2.md missing"
}

if (Get-Command claude.cmd -ErrorAction SilentlyContinue) {
    $mcpList = claude.cmd mcp list 2>&1 | Out-String
    Write-Host ""
    Write-Host $mcpList
    if ($mcpList -match "Connected") {
        Pass "claude.cmd mcp list shows at least one connected server"
    } elseif ($mcpList -match "Pending approval") {
        Warn "Project MCP requires interactive approval. Run: claude.cmd"
    } else {
        Warn "No MCP servers connected yet. Check kubeconfig, Prometheus URL, npm cache, and Claude approval."
    }
} else {
    Warn "claude.cmd not found"
}

Write-Host ""
Write-Host "Result: $pass PASS / $fail FAIL / $warn WARN"
if ($fail -gt 0) {
    exit 1
}
