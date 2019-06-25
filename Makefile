BUILD_DEPS = dh-systemd dh-python python-all python-yaml python-psutil gdebi git git-buildpackage lua5.1 liblua5.1-dev libidn11-dev libssl-dev txt2man quilt postfix

.PHONY: init metronome ssowat moulinette yunohost install uninstall

init:
	apt -o Dpkg::Options::="--force-confold" -y --force-yes install $(BUILD_DEPS)
	mkdir -p /ynh-build/
	cd /ynh-build/; git clone https://github.com/yunohost/moulinette;
	cd /ynh-build/; git clone https://github.com/yunohost/ssowat;
	cd /ynh-build/; git clone https://github.com/yunohost/metronome;
	cd /ynh-build/; git clone https://github.com/yunohost/yunohost;

metronome:
	cd /ynh-build/; rm -f metronome_*; cd metronome; dpkg-buildpackage -rfakeroot -uc -b -d 

ssowat:
	cd /ynh-build/; rm -f ssowat_*; cd ssowat; debuild -us -uc

moulinette:
	cd /ynh-build/; rm -f moulinette_*; cd moulinette; debuild -us -uc

yunohost:
	cd /ynh-build/; rm -f yunohost_*; cd yunohost; debuild -us -uc

install:
	cd /ynh-build/; debconf-set-selections < debconf; export SUDO_FORCE_REMOVE=yes; gdebi /ynh-build/metronome*.deb -n; gdebi /ynh-build/moulinette*.deb -n; gdebi /ynh-build/ssowat*.deb -n; gdebi /ynh-build/yunohost*.deb -n

uninstall:
	apt remove slapd yunohost moulinette --purge -y
	rm -rf /usr/share/yunohost/
	rm -rf /usr/lib/moulinette/
	rm -rf /etc/yunohost/
