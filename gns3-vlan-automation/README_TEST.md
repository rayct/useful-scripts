Excellent — here’s your **finalized `README.md`**, now with a clean, developer-friendly `Makefile` workflow integrated at the end of the environment setup section.

It gives you 3 simple commands:

* `make setup` → creates venv + installs deps
* `make verify` → checks GNS3 server
* `make run` → launches your automation

---

### 🧾 Final `README.md` (with Makefile Integration)

````markdown
# VLAN Lab Automation for GNS3

A fully automated Python script that builds, configures, and tests a multi-VLAN lab in **GNS3** using the REST API via [`gns3fy`](https://github.com/davidban77/gns3fy).

---

## 🚀 Overview

This project automatically:
1. Connects to a running GNS3 server
2. Creates a project named `VLAN_Lab_Automation`
3. Deploys:
   - 1 Router (`R1`)
   - 1 Layer-2 Switch (`SW1`)
   - 6 PCs (`PC1`–`PC6`)
4. Configures:
   - VLANs 10 (Engineering), 20 (HR), 30 (Sales)
   - Router gateway interfaces
   - PC IPs, subnet masks, and gateways
5. Runs **ping tests** from each PC to its default gateway

---

## 🧩 Network Design

| VLAN | Name        | Subnet        | Gateway (last usable) | PCs       |
|------|--------------|---------------|------------------------|------------|
| 10   | Engineering  | 10.0.0.0/26   | 10.0.0.62              | PC1, PC2   |
| 20   | HR           | 10.0.0.64/26  | 10.0.0.126             | PC3, PC4   |
| 30   | Sales        | 10.0.0.128/26 | 10.0.0.190             | PC5, PC6   |

---

## ⚙️ Requirements

### Software
- **GNS3 Server** v2.2.54+ running at `http://172.16.132.128:80`
- **Python 3.8–3.12**
- **Templates** installed in GNS3:
  - `Cisco 2911` (Router)
  - `IOSv-L2` (Switch)
  - `VPCS` (PCs)

### Python Packages
Dependencies are listed in [`requirements.txt`](./requirements.txt):

```bash
# VLAN Lab Automation dependencies
gns3fy==0.8.0
requests==2.32.3
````

---

## 🧰 Environment Setup

You can set up your environment using **either**:

* Automated setup scripts (recommended)
* A simple `Makefile` workflow (for developers)

---

### 🧩 Option 1: Setup Scripts

#### Linux / macOS

```bash
chmod +x setup.sh
./setup.sh
```

#### Windows (PowerShell)

```powershell
.\setup.ps1
```

Both scripts:

* Create a `venv/` folder
* Install from `requirements.txt`
* Run `verify_gns3_setup.py` if found
* Leave you ready to execute the automation script

---

### ⚙️ Option 2: Using Makefile (Linux/macOS Developers)

For convenience, you can use the included `Makefile`:

```bash
make setup   # Create venv + install deps
make verify  # Run verify_gns3_setup.py
make run     # Execute vlan_lab_automation.py
```

Example output:

```
🚀 Creating virtual environment and installing dependencies...
✅ Environment ready!
🧪 Checking GNS3 connection...
✅ GNS3 Server Version: 2.2.54
🚀 Running VLAN Lab Automation...
🎉 VLAN lab deployed and tested successfully!
```

---

## 🧪 Environment Verification (Optional)

If you want to verify manually, create a `verify_gns3_setup.py`:

```python
#!/usr/bin/env python3
from gns3fy import Gns3Connector

GNS3_SERVER_URL = "http://172.16.132.128:80"

try:
    print(f"🔌 Connecting to GNS3 server at {GNS3_SERVER_URL}...")
    server = Gns3Connector(GNS3_SERVER_URL)
    version = server.get_version()
    print(f"✅ Connection successful!")
    print(f"   GNS3 Server Version: {version}")
except Exception as e:
    print(f"❌ Could not connect to GNS3 server: {e}")
```

Run it:

```bash
python3 verify_gns3_setup.py
```

Expected output:

```
🔌 Connecting to GNS3 server at http://172.16.132.128:80...
✅ Connection successful!
   GNS3 Server Version: 2.2.54
```

---

## 🖥️ Running the Lab Automation Script

Once verified, run the automation:

```bash
python3 vlan_lab_automation.py
```

---

## 🧠 What the Script Does

| Step | Action                                        |
| ---- | --------------------------------------------- |
| 1    | Connects to GNS3 server                       |
| 2    | Creates/opens a new project                   |
| 3    | Adds router, switch, and PCs                  |
| 4    | Starts devices                                |
| 5    | Pushes IOS and VPCS configurations via Telnet |
| 6    | Runs ping tests to VLAN gateways              |
| 7    | Prints summary results                        |

---

## 🔍 Example Output

```
✅ Connected to GNS3 server http://172.16.132.128:80
🚀 Deploying nodes...
✅ All nodes started.
💻 Configuring PCs...
📡 Running ping tests...
✅ PC1 → 10.0.0.62 reachable
✅ PC2 → 10.0.0.62 reachable
✅ PC3 → 10.0.0.126 reachable
✅ PC4 → 10.0.0.126 reachable
✅ PC5 → 10.0.0.190 reachable
✅ PC6 → 10.0.0.190 reachable
🎉 VLAN lab fully deployed, configured, and tested!
```

---

## 🧩 Verification

1. Open GNS3.
2. Confirm all devices are running.
3. Switch to Simulation Mode and inspect ICMP flows.
4. Optional: run manual pings from any PC.

---

## 🧹 Cleanup

After testing, stop and delete the project manually from GNS3.
(Auto cleanup and snapshot creation are planned for a future update.)

---

## 🧑‍💻 Author

Developed by **rwxray**
For research and network automation using Python + GNS3.

---

## 🛠️ License

MIT License © 2025


---

### 🧰 Example `Makefile`

```makefile
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
```

---

_**Documentation Maintained By:** Raymond C. Turner_

_**Date:** October 21st, 2025_


