# YunoHost installation scripts

## Context

The script `install_yunohost` will install [YunoHost](https://yunohost.org/) on a Debian system.

Only Debian 9/Stretch systems running with kernel >= 3.12 [systemd](https://wiki.debian.org/systemd) - which is generally the default - are supported.

## Basic usage

With a `curl|bash` syntax : 

    $ curl https://raw.githubusercontent.com/YunoHost/install_script/stretch/install_yunohost | bash

If something goes wrong, you can check the installation logs saved in ```/var/log/yunohost-installation.log```

## Advanced usage

The script supports a number of positional arguments:

    $ bash install_yunohost -h
    Usage :
      install_yunohost [-a] [-d <DISTRIB>] [-h]

    Options :
      -a      Enable automatic mode. No questions are asked.
              This does not perform the post-install step.
      -d      Choose the distribution to install ('stable', 'testing', 'unstable').
              Defaults to 'stable'
      -h      Prints this help and exit

By specifying ```-a```, the installation will be performed without asking any question.
This is useful for fully automated headless installations.
The [post-installation](https://yunohost.org/#/postinstall) will need to be performed later.

The ```-d <DISTRIB>``` switch is mostly for advanced users who want to install the bleeding edge versions of YunoHost packages.

## Issues, Feedback

Please report issues here : https://github.com/YunoHost/issues/issues
