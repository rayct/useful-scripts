<#
VLAN Lab Automation - Environment Setup Script (Windows PowerShell)
Author: rwxray
Description:
  1. Creates a Python virtual environment
  2. Installs dependencies from requirements.txt
  3. Runs environment verification (optional)
  4. Prepares you to run vlan_lab_automation.py
#>

$ProjectName = "VLAN Lab Automation"
$PythonExe = "python"
$VenvDir = "venv"

Write-Host "🚀 Starting setup for $ProjectName" -ForegroundColor Cyan

# --- Step 1: Check for Python ---
if (-not (Get-Command $PythonExe -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Python not found. Please install Python 3.8+ and retry." -ForegroundColor Red
    exit 1
}

# --- Step 2: Create venv if missing ---
if (-not (Test-Path $VenvDir)) {
    Write-Host "🧱 Creating virtual environment..." -ForegroundColor Yellow
    & $PythonExe -m venv $VenvDir
} else {
    Write-Host "✅ Virtual environment already exists." -ForegroundColor Green
}

# --- Step 3: Activate venv ---
Write-Host "⚙️  Activating virtual environment..." -ForegroundColor Cyan
& "$VenvDir\Scripts\Activate.ps1"

# --- Step 4: Upgrade pip ---
Write-Host "⬆️  Upgrading pip..." -ForegroundColor Yellow
pip install --upgrade pip

# --- Step 5: Install requirements ---
if (-not (Test-Path "requirements.txt")) {
    Write-Host "❌ requirements.txt not found. Please add it to your project root." -ForegroundColor Red
    deactivate
    exit 1
}

Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
pip install -r requirements.txt

# --- Step 6: Verify installation ---
if (Test-Path "verify_gns3_setup.py") {
    Write-Host "🧪 Running environment verification..." -ForegroundColor Cyan
    & $PythonExe verify_gns3_setup.py
} else {
    Write-Host "⚠️  No verify_gns3_setup.py found. Skipping verification step." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ Setup complete!" -ForegroundColor Green
Write-Host "💡 To activate your environment later, run:" -ForegroundColor Cyan
Write-Host "   .\venv\Scripts\Activate.ps1"
Write-Host ""
Write-Host "🧩 Next: Run your lab automation script with:" -ForegroundColor Cyan
Write-Host "   python vlan_lab_automation.py"
Write-Host ""
deactivate
Write-Host "👋 Happy automating!" -ForegroundColor Green
exit 0
