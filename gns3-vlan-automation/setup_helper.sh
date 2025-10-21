#!/usr/bin/env bash
# VLAN Lab Automation - Environment Setup Helper Script
# Author: rwxray
# Description:
#   1. Creates a Python virtual environment
#   2. Installs dependencies from requirements.txt
#   3. Runs environment verification (optional)
#   4. Prepares you to run vlan_lab_automation.py

set -e

PROJECT_NAME="VLAN Lab Automation"
PYTHON_BIN="python3"
VENV_DIR="venv"

echo "🚀 Starting setup for ${PROJECT_NAME}"

# --- Step 1: Check for Python ---
if ! command -v $PYTHON_BIN &>/dev/null; then
  echo "❌ Python3 not found. Please install Python 3.8+ and retry."
  exit 1
fi

# --- Step 2: Create venv if missing ---
if [ ! -d "$VENV_DIR" ]; then
  echo "🧱 Creating virtual environment..."
  $PYTHON_BIN -m venv "$VENV_DIR"
else
  echo "✅ Virtual environment already exists."
fi

# --- Step 3: Activate venv ---
echo "⚙️  Activating virtual environment..."
source "$VENV_DIR/bin/activate"

# --- Step 4: Upgrade pip ---
echo "⬆️  Upgrading pip..."
pip install --upgrade pip

# --- Step 5: Install requirements ---
if [ ! -f "requirements.txt" ]; then
  echo "❌ requirements.txt not found. Please add it to your project root."
  deactivate
  exit 1
fi

echo "📦 Installing dependencies..."
pip install -r requirements.txt

# --- Step 6: Verify installation ---
echo "🧪 Running environment verification..."
if [ -f "verify_gns3_setup.py" ]; then
  $PYTHON_BIN verify_gns3_setup.py
else
  echo "⚠️  No verify_gns3_setup.py found. Skipping verification step."
fi

echo ""
echo "✅ Setup complete!"
echo "💡 To activate your environment later, run:"
echo "   source ${VENV_DIR}/bin/activate"
echo ""
echo "🧩 Next: Run your lab automation script with:"
echo "   python3 vlan_lab_automation.py"
echo ""
