#!/bin/bash

# Copyright (C) 2015-2018 YunoHost
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -u

# Globals

readonly YUNOHOST_LOG="/var/log/yunohost-installation_$(date +%Y%m%d_%H%M%S).log"

# Custom colors for whiptail
export NEWT_COLORS='
root=white,black
roottext=white,black
window=white,black
border=white,black
title=white,black
textbox=white,black
button=black,white
compactbutton=white,black
'

###############################################################################
# Main functions                                                              #
###############################################################################

function usage() {
  echo "
Usage :
  `basename $0` [-a] [-d <DISTRIB>] [-h]

Options :
  -a      Enable automatic mode. No questions are asked.
          This does not perform the post-install step.
  -d      Choose the distribution to install ('stable', 'testing', 'unstable').
          Defaults to 'stable'
  -f      Ignore checks before starting the installation. Use only if you know
          what you are doing.
  -h      Prints this help and exit
"
}

function parse_options()
{
    AUTOMODE=0
    DISTRIB=stable
    BUILD_IMAGE=0
    FORCE=0

    while getopts ":aid:fh" option; do
        case $option in
            a)
                AUTOMODE=1
                export DEBIAN_FRONTEND=noninteractive
                ;;
            d)
                DISTRIB=$OPTARG
                ;;
            f)
                FORCE=1
                ;;
            i)
                # This hidden option will allow to build generic image for Rpi/Olimex
                BUILD_IMAGE=1
                ;;
            h)
                usage
                exit 0
                ;;
            :)
                usage
                exit 1
                ;;
            \?)
                usage
                exit 1
                ;;
        esac
    done
}

function main()
{
    parse_options "$@"

    check_assertions

    step upgrade_system                || die "Unable to update the system"
    step install_script_dependencies   || die "Unable to install dependencies to install script"
    step create_custom_config          || die "Creating custom configuration file /etc/yunohost/yunohost.conf failed"
    step confirm_installation          || die "Installation cancelled at your request"
    step manage_sshd_config            || die "Error caught during sshd management"
    step fix_locales                   # do not die for a failure here, it's minor
    step build_packages_locally        || die "Failed to build packages locally"
    step install_local_packages        || die "Failed to install local packages"
    # The following steps rely on having a real deb repo, which we don't have for now
    #step setup_package_source          || die "Setting up deb package sources failed"
    #step apt_update                    || die "Error caught during 'apt-get update'"
    #step register_debconf              || die "Unable to insert new values into debconf database"
    #step workaround_avahi_installation || die "Unable to install workaround for avahi installation"
    #step install_yunohost_packages     || die "Installation of Yunohost packages failed"
    #step restart_services              || die "Error caught during services restart"

    if is_raspbian ; then
        step del_user_pi     || die "Unable to delete user pi"
    fi

    if [[ "$BUILD_IMAGE" == "1" ]] ; then
        step clean_image || die "Unable to clean image"
    fi

    if is_raspbian ; then
        # Reboot should be done before postinstall to be able to run iptables rules
        reboot
    fi

    info "Installation logs are available in $YUNOHOST_LOG"
    success "YunoHost installation completed !"
    conclusion
    exit 0
}

function build_packages_locally()
{
    apt install make -y
    mkdir -p /ynh-build/
    cp ./Makefile ./debconf /ynh-build/
    cd /ynh-build
    make init
    make metronome
    make yunohost
}

function install_local_packages()
{
    cd /ynh-build
    make install
}

###############################################################################
# Helpers                                                                     #
###############################################################################

readonly normal=$(printf '\033[0m')
readonly bold=$(printf '\033[1m')
readonly faint=$(printf '\033[2m')
readonly underline=$(printf '\033[4m')
readonly negative=$(printf '\033[7m')
readonly red=$(printf '\033[31m')
readonly green=$(printf '\033[32m')
readonly orange=$(printf '\033[33m')
readonly blue=$(printf '\033[34m')
readonly yellow=$(printf '\033[93m')
readonly white=$(printf '\033[39m')

function success()
{
  local msg=${1}
  echo "[${bold}${green} OK ${normal}] ${msg}" | tee -a $YUNOHOST_LOG
}

function info()
{
  local msg=${1}
  echo "[${bold}${blue}INFO${normal}] ${msg}" | tee -a $YUNOHOST_LOG
}

function warn()
{
  local msg=${1}
  echo "[${bold}${orange}WARN${normal}] ${msg}" | tee -a $YUNOHOST_LOG >&2
}

function error()
{
  local msg=${1}
  echo "[${bold}${red}FAIL${normal}] ${msg}" | tee -a $YUNOHOST_LOG >&2
}

function die() {
    error "$1"
    info "Installation logs are available in $YUNOHOST_LOG"
    exit 1
}

function step() {
  info "Running $1"
  $*
  local return_code="$?"
  return $return_code
}

function apt_get_wrapper() {
    if [[ "$AUTOMODE" == "0" ]] ;
    then
      debconf-apt-progress                             \
          --logfile $YUNOHOST_LOG                      \
          --                                           \
          apt-get $*
    else
        apt-get $* 2>&1 | tee -a $YUNOHOST_LOG
    fi
}


function apt_update() {
    apt_get_wrapper update
}

###############################################################################
# Installation steps                                                          #
###############################################################################

function check_assertions()
{
    # Assert we're on Debian
    # Note : we do not rely on lsb_release to avoid installing a dependency
    # only to check this...
    [[ -f "/etc/debian_version" ]] || die "This script can only be ran on Debian."

    # Assert we're on Buster
    # Note : we do not rely on lsb_release to avoid installing a dependency
    # only to check this...
    [[ "$(cat /etc/debian_version)" =~ ^10.* ]] || die "This script can only be ran on Debian Buster."

    # Forbid people from installing on Ubuntu or Linux mint ...
    if [[ -f "/etc/lsb-release" ]];
    then
        if cat /etc/lsb-release | grep -q -i "Ubuntu\|Mint"
        then
            die "Please don't try to install YunoHost on an Ubuntu or Linux Mint system ... You need a 'raw' Debian."
        fi
    fi

    # Assert we're root
    [[ "$(id -u)" == "0" ]] || die "This script must be run as root."

    # Assert systemd is installed
    command -v systemctl > /dev/null || die "YunoHost requires systemd to be installed."

    # Check that kernel is >= 3.12, otherwise systemd won't work properly. Cf. https://github.com/systemd/systemd/issues/5236#issuecomment-277779394
    dpkg --compare-versions "$(uname -r)" "ge" "3.12" || die "YunoHost requires a kernel >= 3.12. Please consult your hardware documentation or VPS provider to learn how to upgrade your kernel."

    # If we're on Raspbian, we want the user 'pi' to be logged out because
    # it's going to be deleted for security reasons...
    if is_raspbian ; then
        user_pi_logged_out || die "The user pi should be logged out."
    fi

    # Check possible conflict with apache, bind9.
    [[ -z "$(dpkg --get-selections | grep -v deinstall | grep 'bind9\s')" ]] || [[ "$FORCE" == "1" ]] \
        || die "Bind9 is installed and might conflict with dnsmasq. Uninstall it first, or if you know what you are doing, run this script with -f."

    [[ -z "$(dpkg --get-selections | grep -v deinstall | grep 'apache2\s')" ]] || [[ "$FORCE" == "1" ]] \
        || die "Apache is installed and might conflict with nginx. Uninstall it first, or if you know what you are doing, run this script with -f."

}

function upgrade_system() {

    apt_get_wrapper update \
    || return 1

    # We need libtext-iconv-perl even before the dist-upgrade,
    # otherwise the dist-upgrade might fails on some setups because
    # perl is yolomacnuggets :|
    # Stuff like "Can't locate object method "new" via package "Text::Iconv""
    apt_get_wrapper -o Dpkg::Options::="--force-confold" \
                    -y --force-yes install               \
                    libtext-iconv-perl                   \
    || return 1

    # Manually upgrade grub stuff in non-interactive mode,
    # otherwise a weird technical question is asked to the user
    # regarding how to upgrade grub's configuration...
    DEBIAN_FRONTEND=noninteractive \
    apt_get_wrapper -o Dpkg::Options::="--force-confold" \
                    -y install --only-upgrade \
                    grub-common grub2-common \
    || true

    apt_get_wrapper -o Dpkg::Options::="--force-confold" \
                    -y dist-upgrade \
    || return 2

    if is_raspbian ; then
        apt_get_wrapper -o Dpkg::Options::="--force-confold" \
                        -y --force-yes install rpi-update \
        || return 3

    	if [[ "$BUILD_IMAGE" != "1" ]] ; then
		(rpi-update 2>&1 | tee -a $YUNOHOST_LOG) \
		|| return 4
	fi
    fi
}

function install_script_dependencies() {
    # dependencies of the install script itself
    local DEPENDENCIES="lsb-release wget whiptail gnupg apt-transport-https"

    if [[ "$AUTOMODE" == "0" ]] ;
    then
        DEPENDENCIES+=" dialog"
    fi

    apt_update
    apt_get_wrapper -o Dpkg::Options::="--force-confold" \
                    -y --force-yes install               \
                    $DEPENDENCIES                        \
      || return 1
}

function create_custom_config() {
    # Create YunoHost configuration folder
    mkdir -p /etc/yunohost/
}

function confirm_installation() {
  [[ "$AUTOMODE" == "1" ]] && return 0

  local text="
Caution !

Your configuration files for :
  - postfix
  - dovecot
  - mysql
  - nginx
  - metronome
will be overwritten !

Are you sure you want  to proceed with the installation of Yunohost?
"
  whiptail --title "Yunohost Installation" --yesno "$text" 20 78
}

function manage_sshd_config() {
    # In auto mode we erase the current sshd config
    [[ "$AUTOMODE" == "1" ]] && return 0

    [[ ! -f /etc/ssh/sshd_config ]] && return 0

    local sshd_config_possible_issues="0"
    local text="To improve the security of your server, it is recommended to let YunoHost manage the SSH configuration.
Your current SSH configuration differs from the recommended configuration.
If you let YunoHost reconfigure it, the way you connect to your server through SSH will change in the following way:"

    # If root login is currently enabled
    if ! grep -E "^[[:blank:]]*PermitRootLogin[[:blank:]]+no" /etc/ssh/sshd_config ; then
        sshd_config_possible_issues="1"
        text="$text\n- you will not be able to connect as root through SSH. Instead you should use the admin user ;
"
    fi

    # If current conf uses a custom ssh port
    if grep -Ev "^[[:blank:]]*Port[[:blank:]]+22[[:blank:]]*(#.*)?$" /etc/ssh/sshd_config | grep -E "^[[:blank:]]*Port[[:blank:]]+[[:digit:]]+$" ; then
        sshd_config_possible_issues="1"
        text="$text\n- you will have to connect using port 22 instead of your current custom SSH port. Feel free to reconfigure it after the postinstallation.
"
    fi

    # If we are using DSA key for ssh server fingerprint
    if grep -E "^[[:blank:]]*HostKey[[:blank:]]+/etc/ssh/ssh_host_dsa_key" /etc/ssh/sshd_config ; then
        sshd_config_possible_issues="1"
        text="$text\n- the DSA key will be disabled. Hence, you might later need to invalidate a spooky warning from your SSH client, and recheck the fingerprint of your server ;
"

    fi

    text="${text}
Do you agree to let YunoHost apply those changes to your configuration and therefore affect the way you connect through SSH ?
"

    # If no possible issue found, we just assume it's okay and will take over the SSH conf during postinstall
    [[ "$sshd_config_possible_issues" == "0" ]] && return 0

    # Otherwise, we ask the user to confirm
    if ! whiptail --title "SSH Configuration" --yesno "$text" 20 78 --defaultno --scrolltext ; then

        # Keep a copy to be restored during the postinstall
        # so that the ssh confs behaves as manually modified.
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.before_yunohost
    fi

    return 0
}

function setup_package_source() {

    local CUSTOMAPT=/etc/apt/sources.list.d/yunohost.list

    # Debian repository

    local CUSTOMDEB="deb http://forge.yunohost.org/debian/ buster stable"

    if [[ "$DISTRIB" == "stable" ]] ; then
        echo "$CUSTOMDEB" > $CUSTOMAPT
    elif [[ "$DISTRIB" == "testing" ]] ; then
        echo "$CUSTOMDEB testing" > $CUSTOMAPT
    elif [[ "$DISTRIB" == "unstable" ]] ; then
        echo "$CUSTOMDEB testing unstable" > $CUSTOMAPT
    fi

    # Add YunoHost repository key to the keyring
    wget -O- https://forge.yunohost.org/yunohost.asc -q | apt-key add -qq - >/dev/null 2>&1
}

function register_debconf() {
    debconf-set-selections << EOF
slapd slapd/password1 password yunohost
slapd slapd/password2 password yunohost
slapd slapd/domain    string yunohost.org
slapd shared/organization     string yunohost.org
slapd	slapd/allow_ldap_v2	boolean	false
slapd	slapd/invalid_config	boolean	true
slapd	slapd/backend	select	MDB
postfix postfix/main_mailer_type        select Internet Site
postfix postfix/mailname string /etc/mailname
mariadb-server-10.1 mysql-server/root_password password yunohost
mariadb-server-10.1 mysql-server/root_password_again password yunohost
nslcd	nslcd/ldap-bindpw	password
nslcd	nslcd/ldap-starttls	boolean	false
nslcd	nslcd/ldap-reqcert	select
nslcd	nslcd/ldap-uris	string	ldap://localhost/
nslcd	nslcd/ldap-binddn	string
nslcd	nslcd/ldap-base	string	dc=yunohost,dc=org
libnss-ldapd    libnss-ldapd/nsswitch multiselect group, passwd, shadow
postsrsd postsrsd/domain string yunohost.org
EOF
}

function workaround_avahi_installation() {

    # When attempting several installation of Yunohost on the same host
    # with a light VM system like LXC
    # we hit a bug with avahi-daemon postinstallation
    # This is described in detail in https://github.com/lxc/lxc/issues/25
    #
    # It makes the configure step of avahi-daemon fail, because the service does
    # start correctly. Then all other packages depending on avahi-daemon refuse to
    # configure themselves.
    #
    # The workaround we use is to generate a random uid for the avahi user, and
    # create the user with this id beforehand, so that the avahi-daemon postinst
    # script does not do it on its own. Our randomized uid has far less chances to
    # be already in use in another system than the automated one (which tries to use
    # consecutive uids).

    # Return without error if avahi already exists
    if id avahi > /dev/null 2>&1 ; then
        info "User avahi already exists (with uid $(id avahi)), skipping avahi workaround"
        return 0
    fi

    # Get a random unused uid between 500 and 999 (system-user)
    local avahi_id=$((500 + RANDOM % 500))
    while cut -d ':' -f 3 /etc/passwd | grep -q $avahi_id ;
    do
        avahi_id=$((500 + RANDOM % 500))
    done

    info "Workaround for avahi : creating avahi user with uid $avahi_id"

    # Use the same adduser parameter as in the avahi-daemon postinst script
    # Just specify --uid explicitely
    adduser --disabled-password  --quiet --system     \
        --home /var/run/avahi-daemon --no-create-home \
        --gecos "Avahi mDNS daemon" --group avahi     \
        --uid $avahi_id
}

function install_yunohost_packages() {
    # Allow sudo removal even if no root password has been set (on some DO
    # droplet or Vagrant virtual machines), as YunoHost use sudo-ldap
    export SUDO_FORCE_REMOVE=yes

    # On some machines (e.g. OVH VPS), the /etc/resolv.conf is immutable
    # We need to make it mutable for the resolvconf dependency to be installed
    chattr -i /etc/resolv.conf 2>/dev/null || true

    # Install YunoHost
    apt_get_wrapper \
        -o Dpkg::Options::="--force-confold" \
        -o APT::install-recommends=true      \
        -y --force-yes install               \
        yunohost yunohost-admin postfix      \
    || return 1
}

function restart_services() {
    service slapd restart
#    service yunohost-firewall start
    service unscd restart
    service nslcd restart

    # NOTE : We don't fail if slapd fails to restart...
    return 0
}

function fix_locales() {
    # This function tries to fix the whole locale and perl mess about missing locale files
    
    # Generate at least en_US.UTF-8
    sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && locale-gen
    
    # If no /etc/environment exists, default to en_US.UTF-8
    [ "$(grep LC_ALL /etc/environment)" ] || echo 'LC_ALL="en_US.UTF-8"' >> /etc/environment
    source /etc/environment
    export LC_ALL
}

function conclusion() {
    # Get first local IP and global IP
    local local_ip=$(hostname --all-ip-address | awk '{print $1}')
    local global_ip=$(curl https://ip.yunohost.org 2>/dev/null)

    # Will ignore local ip if it's already the global IP (e.g. for some VPS)
    [[ "$local_ip" != "$global_ip" ]] || local_ip=""

    # Formatting
    [[ -z "$local_ip" ]] || local_ip=$(echo -e "\n    - https://$local_ip/ (local IP, if self-hosting at home)")
    [[ -z "$global_ip" ]] || global_ip=$(echo -e "\n    - https://$global_ip/ (global IP, if you're on a VPS)")

    cat << EOF
===============================================================================
You should now proceed with Yunohost post-installation. This is where you will
be asked for :
  - the main domain of your server ;
  - the administration password.

You can perform this step :
  - from the command line, by running 'yunohost tools postinstall' as root
  - or from your web browser, by accessing : ${local_ip}${global_ip}

If this is your first time with YunoHost, it is strongly recommended to take
time to read the administator documentation and in particular the sections
'Finalizing your setup' and 'Getting to know YunoHost'. It is available at
the following URL : https://yunohost.org/admindoc
===============================================================================
EOF
}

###############################################################################
# Raspbian specific stuff                                                     #
###############################################################################

function is_raspbian() {
    # On Raspbian image lsb_release is available
    if [[ "$(lsb_release -i -s 2> /dev/null)" != "Raspbian" ]] ;
    then
        return 1
    fi
    return 0
}

function user_pi_logged_out() {
    who | grep -w pi > /dev/null && return 1
    return 0
}

function del_user_pi() {
    if id "pi" >/dev/null 2>&1; then
        deluser --remove-all-files pi >> $YUNOHOST_LOG 2>&1
    fi
}

###############################################################################
# Image building specific stuff                                               #
###############################################################################

function clean_image() {
    # Delete SSH keys
    rm -f /etc/ssh/ssh_host_* >> $YUNOHOST_LOG 2>&1
    yes | ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa >> $YUNOHOST_LOG 2>&1
    yes | ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa >> $YUNOHOST_LOG 2>&1
    yes | ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -N '' -t ecdsa -b 521 >> $YUNOHOST_LOG 2>&1

    # Deleting logs ...
    find /var/log -type f -exec rm {} \; >> $YUNOHOST_LOG 2>&1

    # Purging apt ...
    apt-get clean >> $YUNOHOST_LOG 2>&1
}


###############################################################################

main "$@"
