# YunoHost installation script

## Context

The scripts in this repository will install [YunoHost](https://yunohost.org/) on a Debian system.

Only Debian 7 (aka wheezy) and 8 (aka jessie) are supported.

## Basic usage

Go into a temporary folder, e.g. ```/tmp```:

    $ cd /tmp

Get the install script:

    $ wget https://raw.githubusercontent.com/YunoHost/install_script/master/install_yunohostv2

Execute the script:

    $ bash install_yunohostv2

If something goes wrong, you can check the installation logs saved in ```/var/log/yunohost.log```

## Advanced usage

The script supports a number of positionnal arguments:

    $ bash install_yunohostv2 -h
    Usage :
      install_yunohostv2 [-a] [-d <DISTRIB>] [-h]

    Options :
      -a      Enable automatic mode. No questions are asked.
              This does not perform the post-install step.
      -d      Choose the distribution to install ('stable', 'testing', 'unstable').
              Defaults to 'stable'
      -h      Prints this help and exit

By specifying ```-a```, the installation will be performed without asking any question.
This is usefull for fully automated headless installation.
You will need to perform the post-installation later.

The ```-d <DISTRIB>``` switch is mostly for advanced users who wants to install the bleeding edge versions of YunoHost packages.
