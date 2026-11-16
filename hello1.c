// SPDX-License-Identifier: Dual BSD/GPL
#include <linux/init.h>
#include <linux/module.h>
#include <linux/printk.h>
#include <linux/list.h>
#include <linux/ktime.h>
#include <linux/slab.h>
#include "hello1.h"

MODULE_AUTHOR("Iryna Berezhnyak <berezhnyak.iryna@lll.kpi.ua>");
MODULE_DESCRIPTION("Hello1 module: list management and timing");
MODULE_LICENSE("Dual BSD/GPL");

struct hello_event {
	struct list_head list;
	ktime_t time_before;
	ktime_t time_after;
};

static LIST_HEAD(hello_list);

int print_hello(void)
{
	struct hello_event *ev;

	ev = kmalloc(sizeof(*ev), GFP_KERNEL);
	if (!ev)
		return -ENOMEM;

	ev->time_before = ktime_get();
	pr_info("Hello, world!\n");
	ev->time_after = ktime_get();
	list_add_tail(&ev->list, &hello_list);

	return 0;
}
EXPORT_SYMBOL(print_hello);

static int __init hello1_init(void)
{
	pr_info("hello1: module loaded\n");
	return 0;
}

static void __exit hello1_exit(void)
{
	struct hello_event *ev, *tmp;

	list_for_each_entry_safe(ev, tmp, &hello_list, list) {
		pr_info("hello1: print duration = %lld ns\n",
			ktime_to_ns(ktime_sub(ev->time_after,
					      ev->time_before)));
		list_del(&ev->list);
		kfree(ev);
	}
	pr_info("hello1: module unloaded\n");
}

module_init(hello1_init);
module_exit(hello1_exit);
