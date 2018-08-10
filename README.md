# realeyesmwall
To install PowerShell on Ubuntu 16.04 simply:


Import the public repository GPG keys

   curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -


Register the Microsoft Ubuntu repository

   curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list | sudo tee /etc/apt/sources.list.d/microsoft.list


Update apt-get

   sudo apt-get update


Install PowerShell

   sudo apt-get install -y powershell

Start PowerShell
 pwsh

To run the script go ahead and execute:

pwsh /home/user/script.ps1 -inputMP4 /path/to/file.mp4 -segmentTime 5

The segmentTime can be any value but for this purposes it's assumed you will use 6 and then 5 when testing the bonus segment Time.
