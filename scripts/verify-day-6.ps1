$ErrorActionPreference = "SilentlyContinue"

$passCount = 0
$failCount = 0

function Pass($Message) {
  Write-Host "  [PASS] $Message" -ForegroundColor Green
  $script:passCount += 1
}

function Fail($Message) {
  Write-Host "  [FAIL] $Message" -ForegroundColor Red
  $script:failCount += 1
}

Write-Host "=== InsightHub - Verify Day 6 (Security + FinOps) ==="

if (Test-Path "security/promptfooconfig.yaml") {
  Pass "promptfooconfig.yaml exists"
  $promptfoo = Get-Content "security/promptfooconfig.yaml" -Raw
  foreach ($plugin in @("prompt-injection", "indirect-prompt-injection", "pii", "excessive-agency")) {
    if ($promptfoo -match [regex]::Escape($plugin)) {
      Pass "Plugin '$plugin' configured"
    } else {
      Fail "Plugin '$plugin' missing"
    }
  }
} else {
  Fail "security/promptfooconfig.yaml is missing"
}

if ((Test-Path "security/red-team-report.html") -or (Test-Path "security/red-team-final.html")) {
  Pass "Promptfoo red team report exists"
  $reports = Get-ChildItem "security/red-team-*.html"
  $reportText = ($reports | ForEach-Object { Get-Content $_.FullName -Raw }) -join "`n"
  if ($reportText -match "(?i)critical" -and $reportText -notmatch "(?i)0 critical") {
    Fail "Report still references unresolved severe findings"
  } else {
    Pass "Report final has no unresolved severe findings"
  }
}

if (Test-Path "security/threat-model.md") {
  Pass "threat-model.md exists"
  $threatLines = (Select-String -Path "security/threat-model.md" -Pattern "^\|.*\|.*\|").Count
  if ($threatLines -ge 6) {
    Pass "Threat model has $threatLines table entries"
  } else {
    Fail "Threat model has only $threatLines table entries"
  }
} else {
  Fail "security/threat-model.md is missing"
}

if ((Test-Path "security/bedrock-guardrail.json") -or (Test-Path "security/nemo-config")) {
  Pass "Guardrails config exists"
} else {
  Fail "Guardrails config is missing"
}

if ((Test-Path "litellm-config.yaml") -or (Test-Path "security/litellm-config.yaml")) {
  Pass "LiteLLM gateway config exists"
} else {
  Fail "LiteLLM config is missing"
}

if (Test-Path "observability/cost-dashboard.json") {
  try {
    $dashboard = Get-Content "observability/cost-dashboard.json" -Raw | ConvertFrom-Json
    $dashboardText = Get-Content "observability/cost-dashboard.json" -Raw
    if ($dashboard.panels.Count -ge 1 -and $dashboardText -match "llm_cost|tokens_total") {
      Pass "Cost dashboard / panel detected"
    } else {
      Fail "Cost dashboard is missing cost/token signals"
    }
  } catch {
    Fail "Cost dashboard JSON is invalid"
  }
} else {
  Fail "Cost dashboard is missing"
}

Write-Host ""
Write-Host "=== Result: $passCount PASS / $failCount FAIL ==="

if ($failCount -eq 0) {
  Write-Host "Day 6 OK" -ForegroundColor Green
  exit 0
}

Write-Host "Review Day 6 requirements" -ForegroundColor Red
exit 1
