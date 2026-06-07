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

Write-Host "=== InsightHub - Verify Day 5 (ChatOps Bot) ==="

if (Test-Path "chatops-bot/app") {
  foreach ($file in @("main.py", "audit.py")) {
    if (Test-Path "chatops-bot/app/$file") {
      Pass "chatops-bot/app/$file exists"
    } else {
      Fail "chatops-bot/app/$file is missing"
    }
  }

  if (Test-Path "chatops-bot/app/permissions.py") {
    Pass "permissions.py exists"
  } else {
    Fail "permissions.py is missing"
  }

  $appCode = Get-Content "chatops-bot/app/*.py" -Raw
  if ($appCode -match "verify_signature|hmac|x-slack-signature") {
    Pass "Slack signature verification implemented"
  } else {
    Fail "Slack signature verification is missing"
  }

  $mainCode = Get-Content "chatops-bot/app/main.py" -Raw
  if ($mainCode -match "NotImplementedError") {
    Fail "handle_question still raises NotImplementedError"
  } else {
    Pass "handle_question implemented"
  }
} else {
  Fail "chatops-bot/app is missing"
}

if (Test-Path "chatops-bot/Dockerfile") {
  Pass "chatops-bot/Dockerfile exists"
}

if (Test-Path "chatops-bot/chatops-audit.log") {
  try {
    $record = Get-Content "chatops-bot/chatops-audit.log" -First 1 | ConvertFrom-Json
    if ($record.ts -and $record.user -and $record.tool) {
      Pass "Audit log has ts/user/tool"
    } else {
      Fail "Audit log is missing ts/user/tool"
    }
  } catch {
    Fail "Audit log is not valid JSON"
  }
} else {
  Fail "chatops-bot/chatops-audit.log is missing"
}

if ((Test-Path "LOOM-URL.txt") -and ((Get-Content "LOOM-URL.txt" -Raw) -match "loom.com")) {
  Pass "Loom screencast URL referenced"
} else {
  Fail "Loom screencast URL is missing"
}

Write-Host ""
Write-Host "=== Result: $passCount PASS / $failCount FAIL ==="

if ($failCount -eq 0) {
  Write-Host "Day 5 OK" -ForegroundColor Green
  exit 0
}

Write-Host "Review Day 5 requirements" -ForegroundColor Red
exit 1
