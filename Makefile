# SPDX-License-Identifier: GPL-2.0
# Top level Makefile for iproute2

ifeq ("$(origin V)", "command line")
VERBOSE = $(V)
endif
ifndef VERBOSE
VERBOSE = 0
endif

ifeq ($(VERBOSE),0)
MAKEFLAGS += --no-print-directory
endif

#options for AX.25
ADDLIB+=ax25_ntop.o

#options for AX.25
ADDLIB+=rose_ntop.o

#options for mpls
ADDLIB+=mpls_ntop.o mpls_pton.o

#options for NETROM
ADDLIB+=netrom_ntop.o

CC := gcc
HOSTCC ?= $(CC)

SUBDIRS=lib ip tc bridge misc netem genl man
ifeq ($(HAVE_MNL),y)
SUBDIRS += tipc devlink rdma dcb vdpa
endif

all: config.mk
	@set -e; \
	for i in $(SUBDIRS); \
	do echo; echo $$i; $(MAKE) -C $$i; done

.PHONY: clean clobber distclean check cscope version

help:
	@echo "Make Targets:"
	@echo " all                 - build binaries"
	@echo " clean               - remove products of build"
	@echo " distclean           - remove configuration and build"
	@echo " install             - install binaries on local machine"
	@echo " check               - run tests"
	@echo " cscope              - build cscope database"
	@echo " version             - update version"
	@echo ""
	@echo "Make Arguments:"
	@echo " V=[0|1]             - set build verbosity level"

config.mk:
	@if [ ! -f config.mk -o configure -nt config.mk ]; then \
		sh configure $(KERNEL_INCLUDE); \
	fi

install: all
	install -m 0755 -d $(DESTDIR)$(SBINDIR)
	install -m 0755 -d $(DESTDIR)$(CONF_USR_DIR)
	install -m 0755 -d $(DESTDIR)$(HDRDIR)
	@for i in $(SUBDIRS);  do $(MAKE) -C $$i install; done
	install -m 0644 $(shell find etc/iproute2 -maxdepth 1 -type f) $(DESTDIR)$(CONF_USR_DIR)
	install -m 0755 -d $(DESTDIR)$(BASH_COMPDIR)
	install -m 0644 bash-completion/tc $(DESTDIR)$(BASH_COMPDIR)
	install -m 0644 bash-completion/devlink $(DESTDIR)$(BASH_COMPDIR)
	install -m 0644 include/bpf_elf.h $(DESTDIR)$(HDRDIR)

version:
	echo "static const char version[] = \""`git describe --tags --long`"\";" \
		> include/version.h

clean:
	@for i in $(SUBDIRS) testsuite; \
	do $(MAKE) -C $$i clean; done

clobber:
	touch config.mk
	$(MAKE) clean
	rm -f config.mk cscope.*

distclean: clobber

check: all
	$(MAKE) -C testsuite
	$(MAKE) -C testsuite alltests
	@if command -v man >/dev/null 2>&1; then \
		echo "Checking manpages for syntax errors..."; \
		$(MAKE) -C man check; \
	else \
		echo "man not installed, skipping checks for syntax errors."; \
	fi

cscope:
	cscope -b -q -R -Iinclude -sip -slib -smisc -snetem -stc

.EXPORT_ALL_VARIABLES:
