// SPDX-License-Identifier: Dual BSD/GPL
#include <linux/init.h>
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/printk.h>
#include <linux/list.h>
#include <linux/ktime.h>
#include <linux/slab.h>

MODULE_AUTHOR("Iryna Berezhnyak <berezhnyak.iryna@lll.kpi.ua>");
MODULE_DESCRIPTION("Hello, world in Linux Kernel Training");
MODULE_LICENSE("Dual BSD/GPL");

static unsigned int count = 1;
module_param(count, uint, 0444);
MODULE_PARM_DESC(count, "Number of times to print Hello, world! (default 1)");

struct hello_event {
	struct list_head list;
	ktime_t time;
};

static LIST_HEAD(hello_list);

static void hello_free_all(void)
{
	struct hello_event *ev, *tmp;

	list_for_each_entry_safe(ev, tmp, &hello_list, list) {
		pr_info("hello: event time = %lld ns\n",
			ktime_to_ns(ev->time));
		list_del(&ev->list);
		kfree(ev);
	}
}

static int __init hello_init(void)
{
	struct hello_event *ev;
	unsigned int i;

	if (count > 10) {
		pr_err("hello: count = %u is too big (must be <= 10)\n",
		       count);
		return -EINVAL;
	}

	if (count == 0 || count >= 5)
		pr_warn("hello: count = %u, continuing anyway\n", count);

	for (i = 0; i < count; i++) {
		ev = kmalloc(sizeof(*ev), GFP_KERNEL);
		if (!ev) {
			hello_free_all();
			return -ENOMEM;
		}
		ev->time = ktime_get();
		list_add_tail(&ev->list, &hello_list);
		pr_info("Hello, world!\n");
	}

	return 0;
}

static void __exit hello_exit(void)
{
	hello_free_all();
}

module_init(hello_init);
module_exit(hello_exit);
