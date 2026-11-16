// SPDX-License-Identifier: Dual BSD/GPL
#include <linux/init.h>
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/printk.h>
#include <linux/errno.h>
#include "hello1.h"

MODULE_AUTHOR("Iryna Berezhnyak <berezhnyak.iryna@lll.kpi.ua>");
MODULE_DESCRIPTION("Hello2 module: parameter handling and print_hello caller");
MODULE_LICENSE("Dual BSD/GPL");

static unsigned int count = 1;
module_param(count, uint, 0444);
MODULE_PARM_DESC(count, "Number of times to print Hello, world! (default 1)");

static int __init hello2_init(void)
{
	unsigned int i;
	int ret;

	if (count > 10) {
		pr_err("hello2: count = %u is too big (must be <= 10)\n",
		       count);
		return -EINVAL;
	}

	if (count == 0 || count >= 5)
		pr_warn("hello2: count = %u, continuing anyway\n", count);

	for (i = 0; i < count; i++) {
		ret = print_hello();
		if (ret)
			return ret;
	}

	return 0;
}

static void __exit hello2_exit(void)
{
	pr_info("hello2: module unloaded\n");
}

module_init(hello2_init);
module_exit(hello2_exit);
