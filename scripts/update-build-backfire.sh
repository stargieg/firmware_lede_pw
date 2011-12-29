#!/bin/sh

. ./config

for board in $boards ; do
	[ -f "update-build-$verm-$board.lock" ] && echo "build $verm-$board are running. if not do rm update-build-$verm-$board.lock" && exit 0
done

timestamp=`date "+%F_%H-%M"`
echo $timestamp >timestamp
date +"%Y/%m/%d %H:%M">VERSION.txt
echo "Build on $(hostname)" >>VERSION.txt

if [ -d yaffmap-agent ] ; then
	echo "update yaffmap-agent git pull"
	cd yaffmap-agent
	git pull || exit 0
	yaffmap_agent_revision=$(git rev-parse HEAD)
	cd ../
else
	echo "create yaffmap-agent git clone"
	git clone git://github.com/wurststulle/yaffmap-agent.git || exit 0
	cd yaffmap-agent
	yaffmap_agent_revision=$(git rev-parse HEAD)
	cd ../
fi
echo "yaffmap-agent Revision: $yaffmap_agent_revision" >> VERSION.txt

if [ -d luci-app-bulletin-node ] ; then
	echo "update luci-app-bulletin-node git pull"
	cd luci-app-bulletin-node
	git pull || exit 0
	luci_app_bulletin_node_revision=$(git rev-parse HEAD)
	cd ../
else
	echo "create luci-app-bulletin-node git clone"
	git clone git://github.com/rhotep/luci-app-bulletin-node.git || exit 0
	cd luci-app-bulletin-node
	luci_app_bulletin_node_revision=$(git rev-parse HEAD)
	cd ../
fi
echo "luci-app-bulletin-node Revision: $luci_app_bulletin_node_revision" >> VERSION.txt


packages_dir='packages_10.03.1'
if [ -d $packages_dir ] ; then
	echo "update $packages_dir svn up"
	cd $packages_dir
	rm -rf $(svn status)
	if [ -z $packages_revision ] ; then
		svn up  || exit 0
	else
		svn sw -r $packages_revision "svn://svn.openwrt.org/openwrt/branches/$packages_dir"  || exit 0
	fi
	packages_revision=$(svn info | grep Revision | cut -d ' ' -f 2)
	cd ../
else
	echo "create $packages_dir svn co"
	svn co "svn://svn.openwrt.org/openwrt/branches/$packages_dir"
	if [ -z $packages_revision ] ; then
		svn co "svn://svn.openwrt.org/openwrt/branches/$packages_dir"
	else
		svn co "svn://svn.openwrt.org/openwrt/branches/$packages_dir"
		cd $packages_dir
		svn sw -r $packages_revision "svn://svn.openwrt.org/openwrt/branches/$packages_dir"
		cd ..
	fi
	cd $packages_dir
	packages_revision=$(svn info | grep Revision | cut -d ' ' -f 2)
	cd ../
fi
echo "OpenWrt $packages_dir Revision: $packages_revision" >> VERSION.txt

PACKAGESPATCHES="$PACKAGESPATCHES radvd-ifconfig.patch"
PACKAGESPATCHES="$PACKAGESPATCHES olsrd.init_6and4-patches.patch"
PACKAGESPATCHES="$PACKAGESPATCHES package-collectd.patch"
PACKAGESPATCHES="$PACKAGESPATCHES package-collectd-gcrypt.patch"
PACKAGESPATCHES="$PACKAGESPATCHES olsrd.config-rm-wlan-patches.patch"

cd $packages_dir
for i in $PACKAGESPATCHES ; do
	pparm='-p0'
	patch $pparm < ../ff-control/patches/$i || exit 0
done
for i in $PACKAGESRPATCHES ; do
	pparm='-p0 -R'
	#echo "Patch: $i"
	patch $pparm < ../ff-control/patches/$i || exit 0
done
rm -rf $(find . | grep \.orig$)

cd ..

#update and patch repos
if [ -d packages-pberg ] ; then
	echo "update packages-pberg git pull"
	cd packages-pberg
	git pull || exit 0
	packages_pberg_revision=$(git rev-parse HEAD)
	cd ../
else
	echo "create packages-pberg git clone"
	git clone git://github.com/stargieg/packages-pberg.git || exit 0
	cd packages-pberg
	packages_pberg_revision=$(git rev-parse HEAD)
	cd ../
fi
echo "packages-pberg Revision: $packages_pberg_revision" >> VERSION.txt

if [ -d piratenfreifunk-packages ] ; then
	echo "update piratenfreifunk-packages manual git pull"
	cd piratenfreifunk-packages
	git pull || exit 0
	piratenfreifunk_packages_revision=$(git rev-parse HEAD)
	cd ../
else
	echo "create piratenfreifunk-packages git clone"
	git clone git://github.com/basicinside/piratenfreifunk-packages.git || exit 0
	cd piratenfreifunk-packages
	piratenfreifunk_packages_revision=$(git rev-parse HEAD)
	cd ../
fi
echo "piratenfreifunk-packages Revision: $piratenfreifunk_packages_revision" >> VERSION.txt

if [ -d luci-master ] ; then
	echo "update luci-master git pull"
	cd luci-master
	git add .
	rmf="$(git diff --cached | grep 'diff --git a' | cut -d ' ' -f 3 | cut -b 3-)"
	[ -z "$rm" ] || rm "$rmf"
	git reset --hard
	git checkout master .
	git pull || exit 0
	[ -z $luci_version ]  || git checkout $luci_version || exit 0
	[ -z $luci_revision ] || git checkout $luci_revision || exit 0
	luci_revision=$(git rev-parse HEAD)
	cd ../
else
	echo "create HEAD master"
	git clone git://nbd.name/luci.git luci-master || exit 0
	cd luci-master
	[ -z $luci_version ] || git checkout "$luci_version" || exit 0
	[ -z $luci_revision ] || git checkout $luci_revision || exit 0
	luci_revision=$(git rev-parse HEAD)
	cd ../
fi

echo "LUCI Branch: luci-master" >> VERSION.txt
echo "LUCI Revision: $luci_revision" >> VERSION.txt

cd luci-master
LUCIPATCHES="$LUCIPATCHES luci-profile_muenster.patch"
LUCIPATCHES="$LUCIPATCHES luci-profile_cottbus.patch"
LUCIPATCHES="$LUCIPATCHES luci-profile_ndb.patch"
LUCIPATCHES="$LUCIPATCHES luci-profile_ffwtal.patch"
LUCIPATCHES="$LUCIPATCHES luci-profile_berlin.patch"
LUCIPATCHES="$LUCIPATCHES luci-profile_bno.patch"
LUCIPATCHES="$LUCIPATCHES luci-profile_pberg.patch"
LUCIPATCHES="$LUCIPATCHES luci-app-olsr-use-admin-mini.patch"
LUCIPATCHES="$LUCIPATCHES luci-modfreifunk-use-admin-mini.patch"
LUCIPATCHES="$LUCIPATCHES luci-modfreifunk-use-admin-mini-status.patch"
LUCIPATCHES="$LUCIPATCHES luci-modfreifunk-use-admin-mini-makefile.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-sysupgrade.patch"
LUCIPATCHES="$LUCIPATCHES luci-freifunk-common-neighb6.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-splash.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-index.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-backup-style.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-sshkeys.patch"
LUCIPATCHES="$LUCIPATCHES luci-sys-routes6.patch"
LUCIPATCHES="$LUCIPATCHES luci-app-statistics-add-madwifi-olsr.patch"
LUCIPATCHES="$LUCIPATCHES luci-freifunk_radvd_gvpn.patch"
LUCIPATCHES="$LUCIPATCHES luci-freifunk-common.patch"
LUCIPATCHES="$LUCIPATCHES luci-app-splash-css.patch"
LUCIPATCHES="$LUCIPATCHES luci-modfreifunk-migrate.patch"
for i in $LUCIPATCHES ; do
	pparm='-p1'
	echo "Patch: $i"
	patch $pparm < ../ff-control/patches/$i || exit 0
done

rm -rf modules/freifunk/luasrc/controller/freifunk/remote_update.lua
rm -rf modules/freifunk/luasrc/view/freifunk/remote_update.htm
rm -rf contrib/package/freifunk-firewall/files/etc/hotplug.d/iface/22-firewall-nat-fix
rm -rf $(find . | grep \.orig$)
cd ..

rsync_web() {
	build_profile=""
	if [ $1 ] ; then
		build_profile="/$1"
		echo p1$build_profile
	else
		echo n1$build_profile
	fi
	cp build_dir/target-$arch*/root-*/usr/lib/opkg/status ../opkg-$board.status

	#timestamp
	mkdir -p 			                      $wwwdir/$verm/$ver-timestamp/$timestamp/$board$build_profile
	if [ $build_profile ] ; then
		echo p2$build_profile
		rsync -lptgoD bin/*/* 	                      $wwwdir/$verm/$ver-timestamp/$timestamp/$board$build_profile
	else
		echo n2$build_profile
		rsync -lptgoD bin/*/* 	                      $wwwdir/$verm/$ver-timestamp/$timestamp/$board$build_profile
		mkdir -p 			              $wwwdir/$verm/$ver-timestamp/$timestamp/$board$build_profile/packages
		rsync -lptgoD bin/*/packages/* 	              $wwwdir/$verm/$ver-timestamp/$timestamp/$board$build_profile/packages
	fi
	cp build_dir/target-$arch*/root-*/usr/lib/opkg/status $wwwdir/$verm/$ver-timestamp/$timestamp/$board$build_profile/opkg-status.txt
	cp VERSION.txt		 	                      $wwwdir/$verm/$ver-timestamp/$timestamp/$board$build_profile
	cp .config 			                      $wwwdir/$verm/$ver-timestamp/$timestamp/$board$build_profile/config.txt

	#relativ
	rm -f 						      $wwwdir/$verm/$ver/$board$build_profile/*
	mkdir -p 			                      $wwwdir/$verm/$ver/$board$build_profile
	if [ $build_profile ] ; then
		echo p3$build_profile
		rsync -lptgoD bin/*/* 	                      $wwwdir/$verm/$ver/$board$build_profile
	else
		echo n3$build_profile
		rsync -lptgoD bin/*/* 	                      $wwwdir/$verm/$ver/$board$build_profile
		rm -f 					      $wwwdir/$verm/$ver/$board$build_profile/packages/*
		mkdir -p 			              $wwwdir/$verm/$ver/$board$build_profile/packages
		rsync -lptgoD bin/*/packages/* 	              $wwwdir/$verm/$ver/$board$build_profile/packages
	fi
	cp build_dir/target-$arch*/root-*/usr/lib/opkg/status $wwwdir/$verm/$ver/$board$build_profile/opkg-status.txt
	cp VERSION.txt			                      $wwwdir/$verm/$ver/$board$build_profile
	cp .config 			                      $wwwdir/$verm/$ver/$board$build_profile/config.txt
}

for board in $boards ; do
	echo "to see the log just type:"
	echo "tail -f update-build-$verm-$board.log"
	>update-build-$verm-$board.log
	(
	[ -f "update-build-$verm-$board.lock" ] && echo "build $verm-$board are running. if not do rm update-build-$verm-$board.lock" && return 0
	touch "update-build-$verm-$board.lock"
	echo "Board: $board"
	mkdir -p $verm/$board
	cd $verm/$board
	echo "clean up"
	rm -f .config
##	rm -rf tmp
##	rm -rf feeds/*
##	rm -rf package/feeds/*
##	rm -rf bin
#	rm -rf build_dir/*/luci*
##	rm -rf build_dir/*/root*
#	rm -rf build_dir/*/compat-wireless*
#	rm -rf build_dir/*/uhttp*
##	rm -rf build_dir
##	rm -rf staging_dir
	rm -rf files
	mkdir -p files
	rm -rf $(svn status)
	case $verm in
		trunk) 
			svn co svn://svn.openwrt.org/openwrt/trunk ./  || exit 0
			;;
		*)
			svn co svn://svn.openwrt.org/openwrt/branches/$verm ./ || exit 0
			;;
	esac
	if [ -z $openwrt_revision ] ; then
		svn up || exit 0
	else
		case $verm in
			trunk) 
				svn sw -r $openwrt_revision svn://svn.openwrt.org/openwrt/trunk || exit 0
				;;
			*)
				svn sw -r $openwrt_revision svn://svn.openwrt.org/openwrt/branches/$verm || exit 0
				;;
		esac
	fi
	openwrt_revision=$(svn info | grep Revision | cut -d ' ' -f 2)
	cp ../../VERSION.txt VERSION.txt
	echo "OpenWrt Branch: $verm" >> VERSION.txt
	echo "OpenWrt Revision: $openwrt_revision" >> VERSION.txt
	echo "OpenWrt Board: $board" >> VERSION.txt
	cat ../../ff-control/patches/ascii_backfire.txt >> package/base-files/files/etc/banner
	cat VERSION.txt >> package/base-files/files/etc/banner
	echo "URL http://$servername/$verm/$ver-timestamp/$timestamp/$board on $(hostname)">> package/base-files/files/etc/banner
	sed -i -e 's/\(DISTRIB_DESCRIPTION=".*\)"/\1 (r'$openwrt_revision') build date: '$timestamp'"/' package/base-files/files/etc/openwrt_release

	echo "Generate feeds.conf"
	>feeds.conf
	echo "src-link packages ../../../$packages_dir" >> feeds.conf
	echo "src-link packagespberg ../../../packages-pberg" >> feeds.conf
	echo "src-link piratenluci ../../../piratenfreifunk-packages" >> feeds.conf
	echo "src-link luci ../../../luci-master" >> feeds.conf
	#echo "src-link wgaugsburg ../../../wgaugsburg/packages" >> feeds.conf
	echo "src-link yaffmapagent ../../../yaffmap-agent" >> feeds.conf
	echo "src-link bulletin ../../../luci-app-bulletin-node" >> feeds.conf
	#echo "src-link forkeddaapd ../../../forked-daapd" >> feeds.conf
	echo "openwrt feeds update"
	scripts/feeds update
	echo "openwrt feeds install"
	scripts/feeds install -a
	sed -i -e "s,downloads\.openwrt\.org.*,$servername/$verm/$ver-timestamp/$timestamp/$board/packages," package/opkg/files/opkg.conf
	PATCHES="$PATCHES busybox-iproute2.patch"
	PATCHES="$PATCHES base-passwd-admin.patch"
	PATCHES="$PATCHES base-system.patch"
	PATCHES="$PATCHES routerstation-bridge-wan-lan.patch"
	PATCHES="$PATCHES routerstation-pro-bridge-wan-lan.patch"
	PATCHES="$PATCHES brcm-2.4-reboot-fix.patch"
	PATCHES="$PATCHES ar5312_flash_4MB_flash.patch"
	PATCHES="$PATCHES base-disable-ipv6-autoconf.patch"
	PATCHES="$PATCHES package-crda-regulatory-pberg.patch"
	#PATCHES="$PATCHES make-art-writeable.patch"
	#RPATCHES="$RPATCHES packages-r27821.patch"
	#RPATCHES="$RPATCHES packages-r27815.patch"
	for i in $PATCHES ; do
		pparm='-p0'
		echo "Patch: $i"
		patch $pparm < ../../ff-control/patches/$i || exit 0
	done
	for i in $RPATCHES ; do
		pparm='-p2 -R'
		# get patch with:
		# wget --no-check-certificate -O 'ff-control/patches/packages-r27821.patch' 'http://dev.openwrt.org/changeset/27821/branches/backfire/package?format=diff&new=27821'
		# wget --no-check-certificate -O 'ff-control/patches/packages-r27815.patch' 'http://dev.openwrt.org/changeset/27815/branches/backfire/package?format=diff&new=27815'
		echo "Patch: $i"
		patch $pparm < ../../ff-control/patches/$i || exit 0
	done
	rm -rf $(find package | grep \.orig$)
	rm -rf $(find target | grep \.orig$)
	
	mkdir -p ../../dl
	[ -h dl ] || ln -s ../../dl dl
	cp ../../ff-control/patches/regulatory.bin.pberg dl/regulatory.bin.pberg
	echo "copy config ../../ff-control/configs/$verm-$board.config .config"
	cp  ../../ff-control/configs/$verm-$board.config .config
	build_fail=0
	case $board in
		ar71xx)
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_min_options $make_min_options_2_6 || build_fail=1
			rsync_web "minimal"
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_options $make_options_2_6 || build_fail=1
			rsync_web
			rm -f ./bin/*/*
			make -j2 V=99 world $make_options $make_usb_options $make_options_2_6 $make_big_options || build_fail=1
			rsync_web "full"
		;;
		atheros)
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_min_options $make_min_options_2_6 || build_fail=1
			rsync_web "minimal"
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_options $make_options_2_6 || build_fail=1
			rsync_web
		;;
		au1000)
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_min_options $make_min_options_2_6 || build_fail=1
			rsync_web "minimal"
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_options $make_options_2_6 || build_fail=1
			rsync_web
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_options $make_usb_options $make_options_2_6 $make_big_options || build_fail=1
			rsync_web "full"
		;;
		brcm-2.4)
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_min_options || build_fail=1
			rsync_web "minimal"
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_options $make_options_2_4 || build_fail=1
			rsync_web
		;;
		brcm47xx)
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_min_options $make_min_options_2_6 || build_fail=1
			rsync_web "minimal"
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_options $make_options_2_6 || build_fail=1
			rsync_web
		;;
		ixp4xx)
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_min_options $make_min_options_2_6 || build_fail=1
			rsync_web "minimal"
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_options $make_options_2_6 || build_fail=1
			rsync_web
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_options $make_usb_options $make_options_2_6 $make_big_options || build_fail=1
			rsync_web "full"
		;;
		rb532)
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_min_options $make_min_options_2_6 || build_fail=1
			rsync_web "minimal"
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_options $make_options_2_6 || build_fail=1
			rsync_web
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_options $make_usb_options $make_options_2_6 $make_big_options || build_fail=1
			rsync_web "full"
		;;
		x86)
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_min_options $make_min_options_2_6 || build_fail=1
			rsync_web "minimal"
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_options $make_options_2_6 || build_fail=1
			rsync_web
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_options $make_usb_options $make_options_2_6 $make_big_options || build_fail=1
			rsync_web "full"
		;;
		x86_kvm_guest)
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_min_options $make_min_options_2_6 || build_fail=1
			rsync_web "minimal"
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_options $make_options_2_6 || build_fail=1
			rsync_web
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_options $make_options_2_6 $make_big_options || build_fail=1
			rsync_web "full"
		;;
		*)
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_min_options $make_min_options_2_6 || build_fail=1
			rsync_web "minimal"
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_options $make_options_2_6 || build_fail=1
			rsync_web
			rm -f ./bin/*/*
			nice -n 10 make V=99 world $make_options $make_usb_options $make_options_2_6 $make_big_options || build_fail=1
			rsync_web "full"
		;;
	esac
	if [ $build_fail -eq 1 ] ; then
		rm ../../update-build-$verm-$board.lock
		exit 1
	fi
	cd ../../
	rm update-build-$verm-$board.lock
	if [ "$ca_user" != "" -a "$ca_pw" != "" ] ; then
		curl -u "$ca_user:$ca_pw" -d status="$tags New Build #$verm #$ver for #$board Boards http://$servername/$verm/$ver/$board" http://identi.ca/api/statuses/update.xml >/dev/null
	fi
	) >update-build-$verm-$board.log 2>&1
	cp update-build-$verm-$board.log $wwwdir/$verm/$ver-timestamp/$timestamp/$board/update-build-$verm-$board.log.txt
	cp update-build-$verm-$board.log $wwwdir/$verm/$ver/$board/update-build-$verm-$board.log.txt
	#&
	#pid=$!
	#echo $pid > update-build-$verm-$board.pid
done

