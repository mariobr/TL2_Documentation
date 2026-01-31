# Remove IPv6
* https://itsfoss.com/disable-ipv6-ubuntu-linux/
* sudo nano /etc/sysctl.conf
* add following lines
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
* sudo sysctl -p
* sudo reboot
# SSH Server
* sudo apt install openssh-server
* sudo systemctl enable ssh.
* By default, firewall will block ssh access. ...
* Open ssh tcp port 22 using ufw firewall, run: sudo ufw allow ssh.
## Firewall
* sudo ufw allow ssh
* sudo ufw enable
# Prompt
* https://ohmyz.sh/
* * sudo apt install zsh
* sudo apt install git
* sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
