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

Write-Host "=== InsightHub - Verify Day 4 (AIOps) ==="

if ((Test-Path "observability/servicemonitor.yaml") -or (Test-Path "observability/service-monitor.yaml")) {
  Pass "ServiceMonitor manifest exists"
} else {
  Fail "ServiceMonitor manifest is missing"
}

if ((Test-Path "observability/anomaly-rules.yaml") -or (Test-Path "observability/prometheus-rules.yaml")) {
  $rules = ""
  if (Test-Path "observability/anomaly-rules.yaml") {
    $rules += Get-Content "observability/anomaly-rules.yaml" -Raw
  }
  if (Test-Path "observability/prometheus-rules.yaml") {
    $rules += Get-Content "observability/prometheus-rules.yaml" -Raw
  }

  if ($rules -match "_anomaly|_upper_band|_baseline") {
    Pass "Anomaly band recording rules detected"
  } else {
    Fail "Anomaly band recording rules are missing"
  }
} else {
  Fail "Anomaly rules YAML is missing"
}

$dashboardFiles = Get-ChildItem "observability/grafana-dashboards" -Filter "*.json"
if ($dashboardFiles.Count -gt 0) {
  try {
    $dashboard = Get-Content $dashboardFiles[0].FullName -Raw | ConvertFrom-Json
    if ($dashboard.panels.Count -ge 9) {
      Pass "Grafana dashboard has $($dashboard.panels.Count) panels"
    } else {
      Fail "Grafana dashboard has $($dashboard.panels.Count) panels, expected at least 9"
    }
  } catch {
    Fail "Grafana dashboard JSON is invalid"
  }
} else {
  Fail "Grafana dashboard JSON is missing"
}

$rcaFiles = Get-ChildItem "rca-reports" -Filter "incident-*.json"
if ($rcaFiles.Count -ge 3) {
  Pass "RCA reports: $($rcaFiles.Count)"
  foreach ($file in $rcaFiles) {
    try {
      $report = Get-Content $file.FullName -Raw | ConvertFrom-Json
      $evidenceCount = $report.top_hypotheses[0].evidence.Count
      if ($evidenceCount -ge 1) {
        Pass "$($file.Name) has cited evidence"
      } else {
        Fail "$($file.Name) is missing hypothesis evidence"
      }
    } catch {
      Fail "$($file.Name) is invalid JSON"
    }
  }
} else {
  Fail "RCA reports: $($rcaFiles.Count), expected at least 3"
}

if ((Test-Path "mlops-overview-notes.md") -or (Test-Path "docs/mlops-overview-notes.md")) {
  $note = ""
  if (Test-Path "mlops-overview-notes.md") {
    $note += Get-Content "mlops-overview-notes.md" -Raw
  }
  if (Test-Path "docs/mlops-overview-notes.md") {
    $note += Get-Content "docs/mlops-overview-notes.md" -Raw
  }

  $conceptCount = ([regex]::Matches($note, "Mindset|Lifecycle|Registry|Approval|Drift|Rollback|Ownership")).Count
  if ($conceptCount -ge 4) {
    Pass "MLOps overview notes include the required concepts"
  } else {
    Fail "MLOps overview notes are missing required concepts"
  }
} else {
  Fail "mlops-overview-notes.md is missing"
}

Write-Host ""
Write-Host "=== Result: $passCount PASS / $failCount FAIL ==="

if ($failCount -eq 0) {
  Write-Host "Day 4 OK" -ForegroundColor Green
  exit 0
}

Write-Host "Review Day 4 requirements" -ForegroundColor Red
exit 1
