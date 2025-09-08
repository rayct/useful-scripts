## Changed Files Watcher

### Permissions Setup

```shell
sudo chmod +x /usr/local/bin/changed_files.sh
sudo touch /var/log/changed_files.log
sudo chmod 600 /var/log/changed_files.log
sudo touch /etc/changed_files_excludes.txt
sudo chmod 644 /etc/changed_files_excludes.txt
```

### Cron Job

```shell
0 2 * * * /usr/local/bin/changed_files.sh

```