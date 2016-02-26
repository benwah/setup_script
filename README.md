On a new system:
------------------

    cd /opt
    su root -c "apt-get update && apt-get install sudo git lsb-release && adduser $USER sudo"
    # log-out and back-in
    sudo su -c "git clone https://github.com/benwah/setup_script.git /opt/setup_script && chown -R $USER:$USER /opt/setup_script"
    cd /opt/setup_script
    ./setup.sh

TODO:
-----

* [ ] Make lilyterm available to update-alternatives, make principal alternative.
* [ ] Make emacs default editor.
* [ ] Install chrome, make default browser.
* [ ] Set-up keyboard layout switcher.
