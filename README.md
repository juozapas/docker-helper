# docker-helper

Helpers to work with docker on OSX. 

Checkout this to ~/.bash_profile.d and add these line to your ~/.bash_profile.

```bash
if [ -d  $HOME/.bash_profile.d ]; then
    for f in  $HOME/.bash_profile.d/*.bash; do
        source $f;
    done
fi

alias srcbash='source ~/.bash_profile'
```
Use this guide to setup dnsmasq
  - https://passingcuriosity.com/2013/dnsmasq-dev-osx/
 

Credits/More info:
  - http://stackoverflow.com/questions/33711357/how-to-auto-configure-hosts-entry-for-multiple-docker-machine-vms-os-x?answertab=votes#tab-top
  - http://ubuntuforums.org/showthread.php?t=733397
