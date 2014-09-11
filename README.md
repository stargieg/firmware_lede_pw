# Freifunk Firmware Berlin - codename kathleen

*[Kathleen Booth](https://en.wikipedia.org/wiki/Kathleen_Booth) was the author of the first assembly language*

The purpose for this release was not to start a revolution but to have a stable
firmware for our mesh in Berlin. New features like network concepts will be part
of a next release. The firmware itself is based on vanilla OpenWRT with
some modifications (about broken stuff in OpenWRT or luci) and additional
default packages.

## Features

* Based on OpenWRT Barrier Breaker RC4 (new: netifd, procd,...)
* new wizard to configure your router (should start after first boot)
* Support for OLSR 0.6.6.2
* Support for batman-adv 2014.2.0
* Support for VPN03 (OpenVPN setup of Freifunk Berlin)
* Support for collectd monitoring scripts
* `frei.funk` as local DNS entry for your router (you do not have to remember your IP to get access)
* IBSS interface for each frequency
* OLSR on ipv4/6 for each IBSS interface
* one lan segment for APs and lan (dhcpv4 enabled)
* openwifimap integrated

For questions write a mail to berlin@berlin.freifunk.net or come to our weekly
meetings in the [cbase/wikimedia](http://berlin.freifunk.net/contact/) in Berlin.
If you find bugs please report them at: https://github.com/freifunk-berlin/firmware/issues

For the Berlin Freifunk firmware we use vanilla OpenWRT with additional patches
and packages. The Makefile automates firmware
creation and apply patches / integrates custom freifunk packages. All custom
patches are located in *patches/* and all additional packages can be found at
http://github.com/freifunk-berlin/packages_berlin.

After flashing the firmware your router has the IP 192.168.42.1 and distributes IPs on lan switch. You can also access web ui via http://frei.funk

By default this firmware is shipped with [ffwizard-berlin](https://github.com/freifunk-berlin/packages-berlin/tree/master/utils/luci-app-ffwizard-berlin) that may help you to configure your router. If you use the wizard the router's IP is changed to the first IP of the address range you entered during setup. Anyway http://frei.funk should still work.

## HowTo

```
git clone https://github.com/freifunk-berlin/firmware.git
cd firmware
make
```

Then the ImageBuilder files end up in the directory `bin`. You can find the
actuall firmware generated by the ImageBuilder in `firmwares`.

## Required packages
### Ubuntu/Debian
```
apt-get install git subversion build-essential libncurses5-dev zlib1g-dev gawk \
  unzip libxml-perl flex wget gawk libncurses5-dev gettext quilt python
```
## Builds & continuous integration

The firmware is [built
automatically](http://buildbot.berlin.freifunk.net/one_line_per_build) by our [buildbot farm](http://buildbot.berlin.freifunk.net/buildslaves). If you have a bit of CPU+RAM+storage capacity on one of your servers, you can provide a buildbot slave (see [berlin-buildbot](https://github.com/freifunk/berlin-buildbot)).

## Patches with quilt

**Important:** all patches should be pushed upstream!

If a patch is not yet included upstream, it can be placed in the `patches` directory with the `quilt` tool. Please configure `quilt` as described in the [openwrt wiki](http://wiki.openwrt.org/doc/devel/patches) (which also provides a documentation of `quilt`).

### Add, modify or delete a patch

In order to add, modify or delete a patch run:
```bash
make clean pre-patch
```
Then switch to the openwrt directory:
```bash
cd openwrt
```
Now you can use the `quilt` commands as described in the [openwrt wiki](http://wiki.openwrt.org/doc/devel/patches).

#### Example: add a patch
```bash
quilt push -a                 # apply all patches
quilt new 008-awesome.patch   # tell quilt to create a new patch
quilt edit somedir/somefile1  # edit files
quilt edit somedir/somefile2
quilt refresh                 # creates/updates the patch file
```

## Submitting patches

### openwrt

Create a commit in the openwrt directory that contains your change. Use `git
format-patch` to create a patch:

```
git format-patch origin
```

Send a patch to the openwrt mailing list with `git send-email`:

```
git send-email \
  --to=openwrt-devel@lists.openwrt.org \
  --smtp-server=mail.foo.bar \
  --smtp-user=foo \
  --smtp-encryption=tls \
  0001-a-fancy-change.patch
```

Additional information: https://dev.openwrt.org/wiki/SubmittingPatches
