######################################
#
#    RoboPeak USB LCD Display Linux Driver
#    
#    Copyright (C) 2009 - 2013 RoboPeak Team
#    This file is licensed under the GPL. See LICENSE in the package.
#
#    http://www.robopeak.net
#
#    Author Shikai Chen
#
######################################

DRIVER_NAME := rp_usbdisplay
KERNEL_SOURCE_DIR ?= /lib/modules/$(shell uname -r)/build

# When invoked by the kernel build system (KBUILD_EXTMOD is set), these
# variables are evaluated in the kernel build context where $(src) is the
# out-of-tree module directory (the M= path).  When invoked directly by the
# user, $(src) is not yet set, but the outer make below will pass M=$(CURDIR)
# so the kernel build system will set $(src) correctly on re-entry.
ccflags-y += -I$(src)/src -I$(src)/../common

obj-m := $(DRIVER_NAME).o

$(DRIVER_NAME)-objs := src/main.o \
                       src/usbhandlers.o \
                       src/fbhandlers.o \
                       src/touchhandlers.o

# Only define the outer targets when NOT already inside the kernel build system.
ifeq ($(KBUILD_EXTMOD),)

modules:
	$(MAKE) -C $(KERNEL_SOURCE_DIR) M=$(CURDIR) modules

modules_install:
	$(MAKE) -C $(KERNEL_SOURCE_DIR) M=$(CURDIR) modules_install

install: modules_install

clean:
	$(MAKE) -C $(KERNEL_SOURCE_DIR) M=$(CURDIR) clean

endif
