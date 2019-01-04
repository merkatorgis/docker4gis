
# Azure

- Create virtual machine
- Ubuntu Server 18.04 LTS
- password (provide username & password)
- allow selected ports: HTTPS, SSH, RDP
- "Review + create"
- "Create"
- "Go to resource"
- "Serial console"

username=thenameyouchose
sudo apt-get update && sudo apt-get dist-upgrade -y
sudo apt-get install --no-install-recommends ubuntu-mate-core ubuntu-mate-desktop -y
sudo apt-get install mate-core mate-desktop-environment mate-notification-daemon xrdp -y
sudo usermod -aG admin "${username}"
echo mate-session> ~/.xsession
sudo cp "/home/${username}/.xsession" /etc/skel
sudo service xrdp restart
sudo snap install firefox
sudo apt-get install gnome-keyring -y
wget https://github.com/shiftkey/desktop/releases/download/release-1.5.1-linux2/GitHubDesktop-linux-1.5.1-linux2.snap
sudo snap install --dangerous ./GitHubDesktop-linux-1.5.1-linux2.snap
sudo snap connect github-desktop:password-manager-service
sudo snap install --classic vscode
sudo snap install docker


# Windows

- WinKey + R, then enter: mstsc /v:<vmipaddress>

