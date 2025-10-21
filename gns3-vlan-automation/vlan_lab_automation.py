#!/usr/bin/env python3
"""
vlan_lab_automation.py

Creates the VLAN lab in GNS3 and configures R1, SW1, and 6 VPCS hosts.

Adjust the TEMPLATE names and GNS3 server URL at the top as necessary.

Tested approach: uses gns3fy to create nodes/links and uses telnetlib to push CLI to device consoles.
"""

import time
import json
import socket
import telnetlib
import requests
from gns3fy import Gns3Connector, Project, Node, Link

# ---------------------------
# === USER CONFIGURATION ====
# ---------------------------
GNS3_SERVER = "http://172.16.132.128"   # your GNS3 server
PROJECT_NAME = "VLAN_Lab_Automation"

ROUTER_TEMPLATE = "Cisco 2911"   # change to match your template name
SWITCH_TEMPLATE = "IOSv-L2"      # change to match your template name
PC_TEMPLATE = "VPCS"             # usually "VPCS"

# Node naming
ROUTER_NAME = "R1"
SWITCH_NAME = "SW1"
PC_NAMES = [f"PC{i}" for i in range(1, 7)]

# Subnet definitions (/26)
VLAN_INFO = {
    10: {"name": "Engineering", "network": "10.0.0.0",   "pc_ips": ["10.0.0.1", "10.0.0.2"]},
    20: {"name": "HR",          "network": "10.0.0.64",  "pc_ips": ["10.0.0.65", "10.0.0.66"]},
    30: {"name": "Sales",       "network": "10.0.0.128", "pc_ips": ["10.0.0.129", "10.0.0.130"]},
}

SUBNET_MASK = "255.255.255.192"  # /26
CIDR_SUFFIX = "/26"

# Port mapping assumptions (these map adapter indices on nodes)
# We'll keep a straightforward mapping:
# R1 adapters: 0,1,2 connect to SW1 adapters: 0,1,2 (these are GigabitEthernet0/0..0/2 on router)
# SW1 adapters 3..8 will connect to PCs
R1_SW_PORTS = [(0, 0), (1, 1), (2, 2)]  # (router_adapter, switch_adapter)
SW_PC_PORTS = [
    (3, PC_NAMES[0]),  # SW adapter 3 -> PC1
    (4, PC_NAMES[1]),  # SW adapter 4 -> PC2
    (5, PC_NAMES[2]),  # SW adapter 5 -> PC3
    (6, PC_NAMES[3]),  # SW adapter 6 -> PC4
    (7, PC_NAMES[4]),  # SW adapter 7 -> PC5
    (8, PC_NAMES[5]),  # SW adapter 8 -> PC6
]

# Router interface names that correspond to adapter indices (assumption)
ROUTER_IFACES = ["GigabitEthernet0/0", "GigabitEthernet0/1", "GigabitEthernet0/2"]

# ---------------------------
# === Helper functions ======
# ---------------------------
def last_usable_address(network_str):
    # network_str like "10.0.0.0" with /26 mask
    parts = list(map(int, network_str.split('.')))
    base = (parts[0]<<24) | (parts[1]<<16) | (parts[2]<<8) | parts[3]
    # /26 block size = 64, broadcast = base + 63
    broadcast = base + 63
    last_usable = broadcast - 1
    return "{}.{}.{}.{}".format((last_usable>>24)&0xFF, (last_usable>>16)&0xFF, (last_usable>>8)&0xFF, last_usable&0xFF)

def wait_for_telnet(host, port, timeout=30):
    start = time.time()
    while time.time() - start < timeout:
        try:
            s = socket.create_connection((host, port), timeout=2)
            s.close()
            return True
        except Exception:
            time.sleep(0.5)
    return False

def send_ios_commands_via_telnet(host, port, commands, wait_after=0.5, username=None, password=None, enable_password=None):
    """
    Connect to an IOS console via telnet and send commands.
    This is a *best-effort* simple implementation; it does not
    fully implement an expect library.
    """
    tn = telnetlib.Telnet(host, port, timeout=10)
    time.sleep(0.5)
    # Read existing buffer
    try:
        tn.read_very_eager()
    except Exception:
        pass

    def _w(cmd, pause=0.2):
        tn.write(cmd.encode('ascii') + b"\n")
        time.sleep(pause)

    # Enter enable and config
    _w("")  # send newline to get prompt
    if username:
        _w(username); time.sleep(0.2)
    if password:
        _w(password); time.sleep(0.2)
    _w("enable")
    if enable_password:
        _w(enable_password)
    _w("terminal length 0")
    for c in commands:
        _w(c, pause=0.3)
    time.sleep(wait_after)
    output = tn.read_very_eager().decode('ascii', errors='ignore')
    tn.close()
    return output

def send_vpcs_commands(host, port, cmds, wait_after=0.2):
    """
    VPCS console is telnet-like; it accepts commands quickly.
    We'll connect and send the VPCS lines.
    """
    tn = telnetlib.Telnet(host, port, timeout=10)
    time.sleep(0.5)
    for c in cmds:
        tn.write(c.encode('ascii') + b"\n")
        time.sleep(0.15)
    # Optionally read
    try:
        out = tn.read_very_eager().decode('ascii', errors='ignore')
    except Exception:
        out = ""
    tn.close()
    return out

# ---------------------------
# === Main automation flow ==
# ---------------------------
def main():
    print("Connecting to GNS3 server:", GNS3_SERVER)
    connector = Gns3Connector(url=GNS3_SERVER)
    # create project
    proj = Project(name=PROJECT_NAME, connector=connector)
    try:
        proj.create()
        print("Created project:", PROJECT_NAME)
    except Exception:
        # project may already exist; try to get it
        projects = connector.get("projects").json()
        found = None
        for p in projects:
            if p["name"] == PROJECT_NAME:
                found = p
                break
        if not found:
            raise RuntimeError("Could not create or find project on server.")
        proj.project_id = found["project_id"]
        proj.get()
        print("Using existing project:", PROJECT_NAME)

    # Create router node
    router = Node(name=ROUTER_NAME, project_id=proj.project_id, connector=connector, template=ROUTER_TEMPLATE)
    router.create()
    print("Created router:", ROUTER_NAME)

    # Create switch node
    switch = Node(name=SWITCH_NAME, project_id=proj.project_id, connector=connector, template=SWITCH_TEMPLATE)
    switch.create()
    print("Created switch:", SWITCH_NAME)

    # Create PC nodes (VPCS)
    pc_nodes = {}
    for pc_name in PC_NAMES:
        node = Node(name=pc_name, project_id=proj.project_id, connector=connector, template=PC_TEMPLATE)
        node.create()
        pc_nodes[pc_name] = node
        print("Created PC:", pc_name)

    # Refresh nodes to get IDs and adapter info
    proj.get()
    nodes = proj.nodes
    id_map = {n["name"]: n["node_id"] for n in nodes}

    # Build link objects and create links via API
    # We'll call create link endpoints directly via requests for exact adapter indices
    def create_link(node_a_id, adapter_a, port_a, node_b_id, adapter_b, port_b):
        payload = {
            "nodes": [
                {"node_id": node_a_id, "adapter_number": adapter_a, "port_number": port_a},
                {"node_id": node_b_id, "adapter_number": adapter_b, "port_number": port_b}
            ]
        }
        url = f"{GNS3_SERVER}/v2/projects/{proj.project_id}/links"
        r = requests.post(url, json=payload)
        r.raise_for_status()
        return r.json()

    # Create links between R1 and SW1 (3 links)
    for idx, (r_adapter, s_adapter) in enumerate(R1_SW_PORTS):
        print(f"Linking router adapter {r_adapter} to switch adapter {s_adapter}")
        create_link(id_map[ROUTER_NAME], r_adapter, 0, id_map[SWITCH_NAME], s_adapter, 0)

    # Create links from switch to PCs
    # We assume VPCS templates create a single adapter with adapter_number 0 and port_number 0
    # We'll map each PC to an adapter index on the switch as indicated in SW_PC_PORTS
    for (sw_adapter, pc_name) in SW_PC_PORTS:
        print(f"Linking switch adapter {sw_adapter} to {pc_name}")
        create_link(id_map[SWITCH_NAME], sw_adapter, 0, id_map[pc_name], 0, 0)

    print("Links created. Starting nodes...")

    # Start nodes
    for node in nodes:
        node_obj = Node(name=node["name"], project_id=proj.project_id, connector=connector)
        node_obj.node_id = node["node_id"]
        try:
            node_obj.start()
            print("Started", node["name"])
        except Exception as e:
            print("Warning: could not start node", node["name"], e)

    # Wait a bit for consoles to be available
    time.sleep(5)

    # Get node details (to read console_host and console port)
    nodes_detail = requests.get(f"{GNS3_SERVER}/v2/projects/{proj.project_id}/nodes").json()
    node_info = {n["name"]: n for n in nodes_detail}

    # Prepare router configuration commands
    router_cmds = []
    # Set up each router interface with the last usable gateway address for each VLAN
    vlan_list = sorted(VLAN_INFO.keys())
    for idx, vlan in enumerate(vlan_list):
        info = VLAN_INFO[vlan]
        gw = last_usable_address(info["network"])
        iface = ROUTER_IFACES[idx] if idx < len(ROUTER_IFACES) else f"GigabitEthernet0/{idx}"
        router_cmds.append(f"interface {iface}")
        router_cmds.append(f" description Link-to-SW1-VLAN{vlan}")
        router_cmds.append(f" ip address {gw} {SUBNET_MASK}")
        router_cmds.append(" no shutdown")

    # Add a basic hostname and disable domain lookup for cleaner console
    router_full_cfg = ["conf t", f"hostname {ROUTER_NAME}", "no ip domain-lookup"] + router_cmds + ["end", "wr"]

    # Prepare switch configuration commands (IOSv-L2)
    # We'll create VLANs and assign switch ports to VLANs (access)
    sw_cmds = ["conf t", f"hostname {SWITCH_NAME}"]
    for vlan in vlan_list:
        info = VLAN_INFO[vlan]
        sw_cmds.append(f"vlan {vlan}")
        sw_cmds.append(f" name {info['name']}")
    # Map switch adapter numbers to VLANs:
    # We used SW adapters 0..2 for trunk to router (actually router links are access per requirement, each in its own VLAN)
    # We'll make those switch ports access ports in the respective VLANs
    # adapter 0 -> VLAN10, adapter1->VLAN20, adapter2->VLAN30
    sw_adapter_to_vlan = {0: 10, 1: 20, 2: 30}
    # Assign PC ports to VLANs:
    # SW adapter 3 & 4 -> VLAN10 (PC1, PC2)
    # SW adapter 5 & 6 -> VLAN20 (PC3, PC4)
    # SW adapter 7 & 8 -> VLAN30 (PC5, PC6)
    port_vlan_map = {
        3: 10, 4: 10,
        5: 20, 6: 20,
        7: 30, 8: 30
    }
    # configure interfaces on switch
    # Interface naming depends on IOSv-L2 image; commonly GigabitEthernet0/<n>
    for adapter, vlan in sw_adapter_to_vlan.items():
        sw_cmds.append(f"interface GigabitEthernet0/{adapter}")
        sw_cmds.append(f" description Link-to-R1-VLAN{vlan}")
        sw_cmds.append(" switchport mode access")
        sw_cmds.append(f" switchport access vlan {vlan}")
        sw_cmds.append(" no shutdown")
    for adapter, vlan in port_vlan_map.items():
        sw_cmds.append(f"interface GigabitEthernet0/{adapter}")
        sw_cmds.append(f" description Host-port VLAN{vlan}")
        sw_cmds.append(" switchport mode access")
        sw_cmds.append(f" switchport access vlan {vlan}")
        sw_cmds.append(" no shutdown")

    sw_cmds += ["end", "wr"]
    switch_full_cfg = sw_cmds

    # Push configs to router
    r_info = node_info.get(ROUTER_NAME)
    if r_info is None:
        raise RuntimeError("Could not find router node info in project.")
    r_console_host = r_info.get("console_host", "127.0.0.1")
    r_console_port = r_info.get("console")
    print(f"Router console at {r_console_host}:{r_console_port}, waiting for availability...")
    if not wait_for_telnet(r_console_host, r_console_port, timeout=30):
        print("Warning: router console not available within timeout.")
    else:
        print("Pushing router configuration...")
        out = send_ios_commands_via_telnet(r_console_host, r_console_port, router_full_cfg, wait_after=1)
        print("Router config output excerpt:\n", out[:1000])

    # Push configs to switch
    s_info = node_info.get(SWITCH_NAME)
    if s_info is None:
        raise RuntimeError("Could not find switch node info in project.")
    s_console_host = s_info.get("console_host", "127.0.0.1")
    s_console_port = s_info.get("console")
    print(f"Switch console at {s_console_host}:{s_console_port}, waiting for availability...")
    if not wait_for_telnet(s_console_host, s_console_port, timeout=30):
        print("Warning: switch console not available within timeout.")
    else:
        print("Pushing switch configuration...")
        out = send_ios_commands_via_telnet(s_console_host, s_console_port, switch_full_cfg, wait_after=1)
        print("Switch config output excerpt:\n", out[:1000])

    # Configure VPCS hosts
    # VPCS consoles: fetch console info from node_info for each PC
    for pc_name in PC_NAMES:
        p_info = node_info.get(pc_name)
        if p_info is None:
            print("Could not find PC node info for", pc_name)
            continue
        phost = p_info.get("console_host", "127.0.0.1")
        pport = p_info.get("console")
        # compute IP and default gateway from VLAN assignments
        # find which VLAN the PC belongs to by matching PC_NAMES order to VLAN_INFO pc_ips
        assigned_ip = None
        assigned_gw = None
        for vlan, info in VLAN_INFO.items():
            if pc_name in PC_NAMES:
                # check if this PC should have an IP in this VLAN by matching listed PC_IPs order
                for idx, ip in enumerate(info["pc_ips"]):
                    # map: PC1->first ip of VLAN10 etc by overall order
                    # We'll map PC indices to the order given in PC_NAMES
                    # Simpler: assign sequentially in PC_NAMES order based on VLAN ordering
                    pass
        # Instead of complex mapping, use explicit mapping order:
    # We'll map PC1->VLAN10 .1, PC2->VLAN10 .2, PC3->VLAN20 .65, PC4->VLAN20 .66, PC5->VLAN30 .129, PC6->VLAN30 .130
    pc_ip_assignments = {
        "PC1": ("10.0.0.1", "10.0.0.62"),
        "PC2": ("10.0.0.2", "10.0.0.62"),
        "PC3": ("10.0.0.65", "10.0.0.126"),
        "PC4": ("10.0.0.66", "10.0.0.126"),
        "PC5": ("10.0.0.129", "10.0.0.190"),
        "PC6": ("10.0.0.130", "10.0.0.190"),
    }
    for pc_name, (pip, pgw) in pc_ip_assignments.items():
        p_info = node_info.get(pc_name)
        if not p_info:
            print("Missing node info for", pc_name)
            continue
        phost = p_info.get("console_host", "127.0.0.1")
        pport = p_info.get("console")
        print(f"Configuring {pc_name} at {phost}:{pport} -> IP {pip} GW {pgw}")
        if not wait_for_telnet(phost, pport, timeout=20):
            print("Warning: VPCS console not available for", pc_name)
            continue
        vcmds = [
            f"ip {pip} {SUBNET_MASK}",
            f"gateway {pgw}",
            "save"
        ]
        out = send_vpcs_commands(phost, pport, vcmds)
        print(pc_name, "vpcs response excerpt:", out[:200])

    # Allow some time for network convergence
    print("Waiting a few seconds for interfaces to settle...")
    time.sleep(5)

    # Run ping tests from VPCS (using VPCS console)
    def vpcs_ping(pc_name, dest):
        p_info = node_info.get(pc_name)
        if not p_info:
            return False, "no node info"
        phost = p_info.get("console_host", "127.0.0.1")
        pport = p_info.get("console")
        if not wait_for_telnet(phost, pport, timeout=10):
            return False, "no telnet"
        cmds = [f"ping {dest}", "exit"]
        out = send_vpcs_commands(phost, pport, cmds)
        return True, out

    print("Running basic connectivity tests (ping from PC1->PC3 etc)...")
    tests = [("PC1", "10.0.0.65"), ("PC3", "10.0.0.1"), ("PC5", "10.0.0.129")]
    for src, dst in tests:
        ok, result = vpcs_ping(src, dst)
        print(f"{src} -> {dst} ping result (ok={ok}):\n{result}")

    print("Automation complete. Please verify in GNS3 GUI and adjust template names if needed.")

if __name__ == "__main__":
    main()

