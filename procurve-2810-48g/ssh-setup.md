## ✅ **SSH Configuration Guide for HP ProCurve 2810-48G**

---

### 🛠️ **What You’ll Need**:

| Item                        | Description                                              |
| --------------------------- | -------------------------------------------------------- |
| 🧰 Console or Telnet Access | Use a serial cable + PuTTY, or Telnet if already enabled |
| 🧑 Admin Access             | Must have Manager-level privileges                       |
| 🌐 IP Address               | A static IP for management VLAN (e.g., VLAN 1)           |
| 📄 Terminal                 | Software like PuTTY, Tera Term, or SecureCRT             |

---

## 📝 **Configuration Checklist**

| ✅ | Task                                       | Command                                                      |
| - | ------------------------------------------ | ------------------------------------------------------------ |
| ⬜ | Enter privileged mode                      | `enable`                                                     |
| ⬜ | Enter global config                        | `configure`                                                  |
| ⬜ | Set hostname (required for key generation) | `hostname MySwitch`                                          |
| ⬜ | Set IP on VLAN 1                           | `vlan 1` → `ip address 192.168.1.100 255.255.255.0` → `exit` |
| ⬜ | Set default gateway (if needed)            | `ip default-gateway 192.168.1.1`                             |
| ⬜ | Create admin user (if needed)              | `password manager user admin`                                |
| ⬜ | Generate SSH RSA key                       | `crypto key generate ssh`                                    |
| ⬜ | Enable SSH service                         | `ip ssh`                                                     |
| ⬜ | (Optional) Disable Telnet                  | `no telnet-server`                                           |
| ⬜ | Save configuration                         | `write memory`                                               |

---

## 🔧 **Detailed CLI Session Example**

```shell
enable
configure

# Set hostname (required for SSH key generation)
hostname ProCurve2810

# Configure VLAN 1 with a static IP
vlan 1
ip address 192.168.1.100 255.255.255.0
exit

# Optional: set a default gateway if accessing remotely
ip default-gateway 192.168.1.1

# Create a Manager-level user
password manager user admin

# Generate RSA key for SSH (default is 1024 bits)
crypto key generate ssh

# Enable SSH service
ip ssh

# Optional: disable insecure Telnet access
no telnet-server

# Save your configuration
write memory
```

---

## 🧪 **Test SSH Access**

From your terminal:

```bash
ssh admin@192.168.1.100
```

---

## 🛡️ **Verification Commands**

```shell
show ip                      # Confirms IP config
show crypto host-public-key # Shows SSH public key
show ssh                     # Shows SSH status
```

---

## 🧠 Tips for Best Practices

* Use **SSH only** in production (disable Telnet).
* Configure **ACLs** to limit SSH access by IP if needed.
* Use **strong passwords** or SSH key-based auth (ProCurve supports only RSA keys, not public key files like OpenSSH).

---
