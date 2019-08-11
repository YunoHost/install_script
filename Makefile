# YUNoHost locations
YNH_BUILD_DIR = /ynh-build/
YNH_SOURCE = https://github.com/yunohost

BUILD_DEPS = git git-buildpackage postfix python-setuptools
APT_OPTS = -o Dpkg::Options::="--force-confold" -y #--force-yes

.PHONY: init metronome ssowat moulinette yunohost install uninstall mrproper

init:
	apt $(APT_OPTS) install $(BUILD_DEPS)
	mkdir -p "$(YNH_BUILD_DIR)"
	cd "$(YNH_BUILD_DIR)"; \
		git clone "$(YNH_SOURCE)"/moulinette; \
		git clone "$(YNH_SOURCE)"/ssowat; \
		git clone "$(YNH_SOURCE)"/metronome; \
		git clone "$(YNH_SOURCE)"/yunohost;
	apt $(APT_OPTS) build-dep \
		"$(YNH_BUILD_DIR)"/moulinette \
		"$(YNH_BUILD_DIR)"/ssowat \
		"$(YNH_BUILD_DIR)"/metronome \
		"$(YNH_BUILD_DIR)"/yunohost

metronome:
	cd "$(YNH_BUILD_DIR)"; \
		rm -f metronome_*; \
		cd metronome; \
		dpkg-buildpackage -rfakeroot -uc -b -d

ssowat:
	cd "$(YNH_BUILD_DIR)"; \
		rm -f ssowat_*; \
		cd ssowat; \
		debuild -us -uc

moulinette:
	cd "$(YNH_BUILD_DIR)"; \
		rm -f moulinette_*; \
		cd moulinette; \
		debuild -us -uc

yunohost:
	cd "$(YNH_BUILD_DIR)"; \
		rm -f yunohost_*; \
		cd yunohost; \
		debuild -us -uc

install:
	cd "$(YNH_BUILD_DIR)"; \
		debconf-set-selections < debconf; \
		SUDO_FORCE_REMOVE=yes apt install $(APT_OPTS) /ynh-build/*.deb;

mrproper:
	@ rm "$(YNH_BUILD_DIR)" -rfv

uninstall:
	apt remove slapd yunohost moulinette --purge -y
	rm -rf /usr/share/yunohost/
	rm -rf /usr/lib/moulinette/
	rm -rf /etc/yunohost/
