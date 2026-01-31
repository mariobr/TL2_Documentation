# GitHub
* git clone git@github.com:mariobr/TL2.git
## SSH
* sudo -i
* ssh-keygen -t ed25519 -C "mariobr@hotmail.com"
* filename => mariobr.ssh.github
* eval "$(ssh-agent -s)"
* ssh-add ./mariobr.ssh.github

### Add Users
*  git config --global user.email "mariobr@hotmail.com"
*  git config --global user.name "Mario Briana"

### Ownership
* chown -R USERNAME: /PATH/TO/FILE

### SSH Windows
* ssh-keygen -t ed25519 -C "mariobr@hotmail.com"
* ssh-add mariobr.ssh.github
* Get-Service ssh-agent | Start-Service -Verbose!
* Get-Service -Name ssh-agent | Set-Service -StartupType Manual

