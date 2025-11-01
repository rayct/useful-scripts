🌍 Make the Script Global
Option 1 — Global for all users (system-wide)
sudo cp /home/ray/scripts/flash-sd.sh /usr/local/bin/flash-sd
sudo chmod 755 /usr/local/bin/flash-sd


Now you can run it from any directory:

flash-sd


Verify:

which flash-sd
# Output: /usr/local/bin/flash-sd

Option 2 — User-only
mkdir -p ~/bin
cp /home/ray/scripts/flash-sd.sh ~/bin/flash-sd
chmod 755 ~/bin/flash-sd


Add ~/bin to your PATH (if it isn’t already):

echo 'export PATH=$PATH:~/bin' >> ~/.bashrc
source ~/.bashrc


Now flash-sd works anywhere for your user only.