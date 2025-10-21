# Makefile for VLAN Lab Automation
PYTHON=python3
VENV=venv

setup:
	@echo "🚀 Creating virtual environment and installing dependencies..."
	$(PYTHON) -m venv $(VENV)
	@. $(VENV)/bin/activate && pip install --upgrade pip && pip install -r requirements.txt
	@echo "✅ Environment ready!"

verify:
	@. $(VENV)/bin/activate && $(PYTHON) verify_gns3_setup.py || echo "⚠️ Verification script missing."

run:
	@. $(VENV)/bin/activate && $(PYTHON) vlan_lab_automation.py
