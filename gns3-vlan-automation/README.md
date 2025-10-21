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
```bash
pip install gns3fy requests
````

---

## 🖥️ Running the Script

Clone or copy this repository, then execute:

```bash
python3 vlan_lab_automation.py
```

---

## 🧠 What the Script Does

| Step | Action                                           |
| ---- | ------------------------------------------------ |
| 1    | Connects to GNS3 server                          |
| 2    | Creates/opens a new project                      |
| 3    | Adds all nodes (router, switch, 6 PCs)           |
| 4    | Starts devices                                   |
| 5    | Pushes IOS and VPCS configurations via Telnet    |
| 6    | Runs ping tests from each PC to its VLAN gateway |
| 7    | Prints success/failure results                   |

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
2. Confirm all devices (R1, SW1, PC1–PC6) are running.
3. Use simulation mode to watch traffic.
4. Manually test:

   ```bash
   ping 10.0.0.62
   ping 10.0.0.126
   ping 10.0.0.190
   ```

---

## 🧹 Cleanup

After testing, stop and delete the project:

```bash
gns3fy --delete-project VLAN_Lab_Automation
```

---

## 🧑‍💻 Author

Developed by **rwxray**
For research and network automation experiments using Python + GNS3.

---

## 🛠️ License

MIT License © 2025

---

### ChatGPT

✅ **Next Steps:**
1. Save the script and `README.md` in the same directory.  
2. Run `python3 vlan_lab_automation.py`.  
3. Watch your GNS3 topology build itself, configure automatically, and confirm connectivity with live ping results.

Would you like me to also include **automatic cleanup (project delete)** or snapshot creation at the end for easier lab resets?


---

_**Documentation Maintained By:** Raymond C. Turner_

_**Date:** October 21st, 2025_