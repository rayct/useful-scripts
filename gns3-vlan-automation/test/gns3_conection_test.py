#!/usr/bin/env python3
"""
Simple test script to confirm GNS3 API connectivity and list available templates.
"""

from gns3fy import Gns3Connector
import sys

# Change this to your GNS3 server URL
GNS3_SERVER = "http://172.16.132.128:80"

try:
    server = Gns3Connector(GNS3_SERVER)
    print(f"✅ Connected to GNS3 Server at {GNS3_SERVER}")
    print(f"Server version: {server.get_version()}")

    # Fetch and list available templates
    templates = server.get_templates()
    print("\n📦 Available GNS3 Templates:")
    for t in templates:
        print(f" - {t['name']} ({t['template_type']})")

    print("\n✅ Connection test successful!")

except Exception as e:
    print(f"❌ Could not connect to GNS3 server at {GNS3_SERVER}")
    print(f"Error: {e}")
    sys.exit(1)
