
# Development environment on Cloud VM

Since many standard laptops aren't equipped to run a full Docker development environment, a (temporary) setup in the cloud might be an easy way to get you started.

## Setup Cloud VM

### Azure

Login on [Microsoft Azure](https://portal.azure.com). New accounts come with a free USD 200,-- credit.

- Choose to add a virtual machine resource
- Image: Ubuntu Server 18.04 LTS
- Size: Standard D2s v3 (2 vcpus, 8 GB memory)
- Authentication type: Password (provide username & password)
- Allow selected ports: HTTPS, SSH, RDP
- "Review + create"
- "Create"
- "Go to resource"
- "Serial console"
- In the console, set the username variable by typing: `username=theusernameyouchose`
- Then run the following (first 3 command take like 10 minutes):

``` bash
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
```

## Connect with Remote Desktop

### Windows

- WinKey + R, then enter: `mstsc /v:ipaddressofyourvm`

