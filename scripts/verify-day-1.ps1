param(
    [string]$ApiUrl = "http://localhost:8000",
    [string]$SampleFile = "sample-docs/huong-dan-nguoi-moi.md"
)

$ErrorActionPreference = "Stop"

function Fail($Message) {
    Write-Host "[FAIL] $Message" -ForegroundColor Red
    exit 1
}

function Pass($Message) {
    Write-Host "[PASS] $Message" -ForegroundColor Green
}

Write-Host "InsightHub Day 1 verification"
Write-Host "API: $ApiUrl"
Write-Host ""

if (-not (Get-Command curl.exe -ErrorAction SilentlyContinue)) {
    Fail "curl.exe not found. Run this script on Windows with curl.exe available."
}

if (-not (Test-Path $SampleFile)) {
    Fail "Sample file not found: $SampleFile"
}

try {
    curl.exe -fsS "$ApiUrl/healthz" | Out-Null
    Pass "API healthz is OK"
}
catch {
    Fail "API is not reachable at $ApiUrl/healthz. Start services with: docker-compose up --build -d"
}

$responseFile = New-TemporaryFile
try {
    $statusCode = curl.exe -sS -o $responseFile.FullName -w "%{http_code}" `
        -X POST `
        -F "file=@$SampleFile" `
        "$ApiUrl/documents"

    $body = Get-Content $responseFile.FullName -Raw

    if ($statusCode -ne "202") {
        Write-Host $body
        Fail "POST /documents returned HTTP $statusCode, expected 202"
    }

    $upload = $body | ConvertFrom-Json
    if (-not $upload.id) {
        Write-Host $body
        Fail "Upload response does not contain document id"
    }

    Pass "Upload accepted: document id $($upload.id), job id $($upload.job_id)"

    $ready = $false
    for ($i = 1; $i -le 12; $i++) {
        Start-Sleep -Seconds 2
        $docs = curl.exe -fsS "$ApiUrl/documents" | ConvertFrom-Json
        $doc = $docs | Where-Object { $_.id -eq $upload.id } | Select-Object -First 1
        if ($doc -and $doc.status -eq "ready") {
            Pass "Worker processed document $($upload.id): status ready, chunks $($doc.chunk_count)"
            $ready = $true
            break
        }
        Write-Host "Waiting for worker... attempt $i/12"
    }

    if (-not $ready) {
        Fail "Document $($upload.id) did not become ready. Check: docker-compose logs -f ingestion-worker"
    }
}
finally {
    Remove-Item -LiteralPath $responseFile.FullName -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Pass "Day 1 async ingestion flow is working"
