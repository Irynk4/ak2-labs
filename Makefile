ifneq ($(KERNELRELEASE),)
include Kbuild
else
KDIR ?= /work/src/linux-stable
PWD := $(shell pwd)

default:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
endif
