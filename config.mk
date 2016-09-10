# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx_generic
#TARGET=ar71xx_mikrotik
#TARGET=ath25_generic
#TARGET=mpc85xx_generic
#TARGET=ramips_mt7620
#TARGET=x86_generic
#TARGET=x86_geode
#TARGET=x86_64
PACKAGES_LIST_DEFAULT=luci-lua-olsrv2 luci-ng-olsrv2
LEDE_SRC=git://git.lede-project.org/source.git
LEDE_COMMIT=c1578d4fc9e53c9b80d858fc924adc8a66f5fce3
