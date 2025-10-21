#!/usr/bin/env python3
"""
Quick check to verify:
- Python environment setup
- gns3fy + requests installed
- GNS3 server reachable
"""

from gns3fy import Gns3Connector

# Update this if your GNS3 server runs on a different host/port
GNS3_SERVER_URL = "http://172.16.132.128:80"

try:
    print(f"🔌 Connecting to GNS3 server at {GNS3_SERVER_URL}...")
    server = Gns3Connector(GNS3_SERVER_URL)
    version = server.get_version()
    print(f"✅ Connection successful!")
    print(f"   GNS3 Server Version: {version}")
except Exception as e:
    print(f"❌ Could not connect to GNS3 server: {e}")
