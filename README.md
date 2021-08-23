# YunoHost installation scripts

Please report any issue/feedback on https://github.com/YunoHost/issues/issues

## Context

The script `install_yunohost` will install [YunoHost](https://yunohost.org/) on a Debian system.

Only Debian systems running with kernel >= 3.12 [systemd](https://wiki.debian.org/systemd) - which is generally the default - are supported.

## Basic usage

With a `curl|bash` syntax : 

```bash
$ curl https://raw.githubusercontent.com/YunoHost/install_script/main/<distname> | bash
```

If something goes wrong, you can check the installation logs saved in `/var/log/yunohost-installation.log`

## Advanced usage

The script supports a number of positional arguments:

```
$ bash install_yunohost -h
Usage :
  install_yunohost [-a] [-d <DISTRIB>] [-h]

Options :
  -a      Enable automatic mode. No questions are asked.
          This does not perform the post-install step.
  -d      Choose the distribution to install ('stable', 'testing', 'unstable').
          Defaults to 'stable'
  -h      Prints this help and exit
```

Option `-a` is useful for fully automated headless installations.

The [post-installation](https://yunohost.org/#/postinstall) will have to be performed later.
