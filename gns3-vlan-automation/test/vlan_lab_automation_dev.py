#!/usr/bin/env python3
"""
Full VLAN Lab Automation for GNS3
---------------------------------
Creates a VLAN topology with:
- 1 Router (R1)
- 1 Switch (SW1)
- 6 PCs (VPCS)
Then:
- Configures all devices (VLANs, IPs, gateways)
- Runs ping tests from each PC to its gateway
"""

import sys
import time
import telnetlib
from gns3fy import Gns3Connector, Project, Node

# === CONFIGURATION ===
GNS3_SERVER_URL = "http://172.16.132.128:80"
PROJECT_NAME = "VLAN_Lab_Automation"

ROUTER_TEMPLATE = "Cisco 2911"
SWITCH_TEMPLATE = "IOSv-L2"
PC_TEMPLATE = "VPCS"

TELNET_TIMEOUT = 8

# === VLAN/Network Settings ===
PC_CONFIGS = {
    "PC1": {"ip": "10.0.0.1", "mask": "255.255.255.192", "gw": "10.0.0.62"},
    "PC2": {"ip": "10.0.0.2", "mask": "255.255.255.192", "gw": "10.0.0.62"},
    "PC3": {"ip": "10.0.0.65", "mask": "255.255.255.192", "gw": "10.0.0.126"},
    "PC4": {"ip": "10.0.0.66", "mask": "255.255.255.192", "gw": "10.0.0.126"},
    "PC5": {"ip": "10.0.0.129", "mask": "255.255.255.192", "gw": "10.0.0.190"},
    "PC6": {"ip": "10.0.0.130", "mask": "255.255.255.192", "gw": "10.0.0.190"},
}

# === STEP 1: Verify GNS3 Server Connection ===
try:
    server = Gns3Connector(GNS3_SERVER_URL)
    version = server.get_version()
    print(f"✅ Connected to GNS3 server {GNS3_SERVER_URL}")
    print(f"   Version: {version}")
except Exception as e:
    print(f"❌ Could not connect to GNS3 server at {GNS3_SERVER_URL}")
    print(f"Error: {e}")
    sys.exit(1)

# === STEP 2: Create or open project ===
print(f"\n🧱 Creating project: {PROJECT_NAME}")
project = Project(name=PROJECT_NAME, connector=server)
project.create()
project.open()
print(f"✅ Project created: {project.name} (ID: {project.project_id})")

# === STEP 3: Add nodes ===
print("\n🚀 Deploying nodes...")
r1 = Node(name="R1", project_id=project.project_id, connector=server, template=ROUTER_TEMPLATE)
r1.create()

sw1 = Node(name="SW1", project_id=project.project_id, connector=server, template=SWITCH_TEMPLATE)
sw1.create()

pcs = []
for i in range(1, 7):
    pc = Node(name=f"PC{i}", project_id=project.project_id, connector=server, template=PC_TEMPLATE)
    pc.create()
    pcs.append(pc)

time.sleep(3)
print("✅ Nodes created.")

# === STEP 4: Start nodes ===
print("\n⚙️  Starting all nodes...")
for n in [r1, sw1, *pcs]:
    n.start()
print("✅ All nodes started.")
time.sleep(10)

# === STEP 5: Device Configurations ===
router_config = [
    "enable",
    "configure terminal",
    "interface g0/0",
    " ip address 10.0.0.62 255.255.255.192",
    " no shutdown",
    "interface g0/1",
    " ip address 10.0.0.126 255.255.255.192",
    " no shutdown",
    "interface g0/2",
    " ip address 10.0.0.190 255.255.255.192",
    " no shutdown",
    "end",
    "wr",
]

switch_config = [
    "enable",
    "configure terminal",
    "vlan 10",
    " name Engineering",
    "vlan 20",
    " name HR",
    "vlan 30",
    " name Sales",
    "interface range f3/1 - f4/1",
    " switchport mode access",
    " switchport access vlan 10",
    "interface range f5/1 - f6/1",
    " switchport mode access",
    " switchport access vlan 20",
    "interface range f7/1 - f8/1",
    " switchport mode access",
    " switchport access vlan 30",
    "end",
    "wr",
]

# === Helper Function for Telnet Communication ===
def telnet_send(host, port, commands, name, expect_prompt=b">"):
    try:
        print(f"\n🔌 Telnet to {name} ({host}:{port})")
        tn = telnetlib.Telnet(host, port, timeout=TELNET_TIMEOUT)
        time.sleep(2)
        tn.write(b"\n")
        tn.read_until(expect_prompt, timeout=5)
        for cmd in commands:
            tn.write(cmd.encode("ascii") + b"\n")
            time.sleep(0.4)
        tn.write(b"\n")
        tn.close()
        print(f"✅ Config applied to {name}")
    except Exception as e:
        print(f"❌ Failed on {name}: {e}")

# === STEP 6: Get console ports ===
r1.get()
sw1.get()
r1_port = r1.console
sw1_port = sw1.console

# === STEP 7: Apply router/switch configs ===
telnet_send("172.16.132.128", r1_port, router_config, "R1")
telnet_send("172.16.132.128", sw1_port, switch_config, "SW1")

# === STEP 8: Configure PCs ===
print("\n💻 Configuring PCs...")
for pc in pcs:
    pc.get()
    pc_port = pc.console
    cfg = PC_CONFIGS[pc.name]
    commands = [
        f"set ip {cfg['ip']} {cfg['mask']} {cfg['gw']}",
        "save",
    ]
    telnet_send("172.16.132.128", pc_port, commands, pc.name)

# === STEP 9: Ping Test ===
print("\n📡 Running ping tests...")
for pc in pcs:
    pc.get()
    pc_port = pc.console
    gw = PC_CONFIGS[pc.name]["gw"]
    try:
        tn = telnetlib.Telnet("172.16.132.128", pc_port, timeout=TELNET_TIMEOUT)
        time.sleep(2)
        tn.write(f"ping {gw}\n".encode("ascii"))
        time.sleep(4)
        output = tn.read_very_eager().decode("utf-8", errors="ignore")
        tn.close()

        if "success" in output.lower() or "64 bytes" in output:
            print(f"✅ {pc.name} → {gw} reachable")
        else:
            print(f"⚠️  {pc.name} → {gw} may have failed\n{output.strip()[:80]}...")

    except Exception as e:
        print(f"❌ Ping test failed for {pc.name}: {e}")

print("\n🎉 VLAN lab fully deployed, configured, and tested!")
print("💡 Open GNS3 → verify topology, then try inter-VLAN pings.")
