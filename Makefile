# YUNoHost locations
YNH_BUILD_DIR = /ynh-build
YNH_SOURCE = https://github.com/yunohost

BUILD_DEPS = git git-buildpackage postfix python-setuptools
APT_OPTS = -o Dpkg::Options::="--force-confold" -y

.PHONY: init metronome ssowat moulinette yunohost install uninstall mrproper \
	postinstall appinstall

init:
	@ apt $(APT_OPTS) install $(BUILD_DEPS)
	@ mkdir -vp "$(YNH_BUILD_DIR)"
	@ cd "$(YNH_BUILD_DIR)"                 \
	&& git clone "$(YNH_SOURCE)/moulinette" \
	&& git clone "$(YNH_SOURCE)/ssowat"     \
	&& git clone "$(YNH_SOURCE)/metronome"  \
	&& git clone "$(YNH_SOURCE)/yunohost"
	@ cd "$(YNH_BUILD_DIR)/moulinette" \
	&& git checkout buster-unstable
	@ cd "$(YNH_BUILD_DIR)/yunohost" \
	&& git checkout buster-unstable
	@ apt $(APT_OPTS) build-dep           \
		"$(YNH_BUILD_DIR)/moulinette" \
		"$(YNH_BUILD_DIR)/ssowat"     \
		"$(YNH_BUILD_DIR)/metronome"  \
		"$(YNH_BUILD_DIR)/yunohost"

metronome:
	@ cd "$(YNH_BUILD_DIR)" \
	&& rm -vf metronome_*   \
	&& cd metronome         \
	&& dpkg-buildpackage -rfakeroot -uc -b -d

ssowat:
	@ cd "$(YNH_BUILD_DIR)" \
	&& rm -vf ssowat_*      \
	&& cd ssowat            \
	&& debuild -us -uc

moulinette:
	@ cd "$(YNH_BUILD_DIR)" \
	&& rm -vf moulinette_*  \
	&& cd moulinette        \
	&& debuild -us -uc

yunohost:
	@ cd "$(YNH_BUILD_DIR)" \
	&& rm -vf yunohost_*    \
	&& cd yunohost          \
	&& debuild -us -uc

install:
	@ cd "$(YNH_BUILD_DIR)"             \
	&& debconf-set-selections < debconf \
	&& apt install $(APT_OPTS)          \
		./metronome_*.deb           \
		./moulinette_*.deb          \
		./ssowat_*.deb              \
	&& SUDO_FORCE_REMOVE=yes apt install $(APT_OPTS) ./yunohost_*.deb;

postinstall:
	@ yunohost tools postinstall -d e.org -p Yunohost

appinstall:
	@ yunohost app install https://github.com/YunoHost-Apps/helloworld_ynh
appuninstall:
	@ yunohost app remove helloworld

mrproper: uninstall
	@ rm "$(YNH_BUILD_DIR)" -rfv

uninstall:
	@ apt  -y --allow-remove-essential purge \
		yunohost moulinette slapd nginx-common
	@ rm -rvf /usr/share/yunohost/
	@ rm -rvf /usr/lib/moulinette/
	@ rm -rvf /etc/yunohost/
