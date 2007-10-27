module dfl.internal.gtkcontainer;

import dfl.internal.gtk;


alias void delegate(GtkWidget* widget, GtkRequisition* requisition) SizeRequestDg;
alias void delegate(GtkWidget* widget, GtkAllocation* allocation) SizeAllocateDg;


struct DflGtkContainer
{
	GtkContainer parent;
	GList* children;
	SizeRequestDg sizeRequest;
	SizeAllocateDg sizeAllocate;
}


struct DflGtkContainerClass
{
	GtkContainerClass parent;
}


extern(C) GType dflGtkContainer_get_type()
{
	if(_containertype == 0)
	{
		GTypeInfo info;
		info.class_size = DflGtkContainerClass.sizeof;
		info.class_init = cast(GClassInitFunc)&dflGtkContainer_class_init;
		info.instance_size = DflGtkContainer.sizeof;
		info.instance_init = cast(GInstanceInitFunc)&dflGtkContainer_init;
		_containertype = g_type_register_static(gtk_container_get_type(), "DflGtkContainer", &info, cast(GTypeFlags)0);
	}
	return _containertype;
}


extern(C) void dflGtkContainer_class_init(DflGtkContainerClass* cls, gpointer p)
{
	GtkWidgetClass* wcls = cast(GtkWidgetClass*)cls;
	GtkContainerClass* ccls = cast(GtkContainerClass*)cls;
	
	_parentclass = cast(GtkContainerClass*)g_type_class_peek_parent(cls);
	wcls.realize = &dflGtkContainer_realize;
	wcls.size_request = &dflGtkContainer_size_request;
	wcls.size_allocate = &dflGtkContainer_size_allocate;
	ccls.add = &dflGtkContainer_add;
	ccls.remove = &dflGtkContainer_remove;
	ccls.forall = &dflGtkContainer_forall;
	ccls.child_type = &dflGtkContainer_child_type;
}


extern(C) GType dflGtkContainer_child_type(GtkContainer* container)
{
	return gtk_widget_get_type();
}


extern(C) void dflGtkContainer_init(DflGtkContainer* c)
{
	GtkObject* obj = cast(GtkObject*)c;
	obj.flags = GtkWidgetFlags.GTK_NO_WINDOW;
	c.children = null;
	c.sizeRequest = null;
	c.sizeAllocate = null;
}


extern(C) GtkWidget* dflGtkContainer_new()
{
	return cast(GtkWidget*)g_object_new(dflGtkContainer_get_type(), null);
}


extern(C) void dflGtkContainer_add(GtkContainer* c, GtkWidget* widget)
{
	DflGtkContainer* mwc = cast(DflGtkContainer*)c;
	GtkWidget* child = widget;
	gtk_widget_set_parent(widget, cast(GtkWidget*)c);
	mwc.children = g_list_append(mwc.children, child);
}


extern(C) void dflGtkContainer_realize(GtkWidget* widget)
{
	GtkWidgetClass* wcls = cast(GtkWidgetClass*)_parentclass;
	wcls.realize(widget);
}


extern(C) void dflGtkContainer_size_request(GtkWidget* w, GtkRequisition* req)
{
	DflGtkContainer* c = cast(DflGtkContainer*)w;
	req.width = 0;
	req.height = 0;
	if(c.sizeRequest !is null)
	{
		c.sizeRequest(w, req);
	}
}


extern(C) void dflGtkContainer_size_allocate(GtkWidget* w, GtkAllocation* a)
{
	DflGtkContainer* c = cast(DflGtkContainer*)w;
	w.allocation = *a;
	if(c.sizeAllocate !is null)
	{
		c.sizeAllocate(w, a);
	}
}


extern(C) void dflGtkContainer_remove(GtkContainer* container, GtkWidget* widget)
{
	DflGtkContainer *c;
	GtkWidget *child;
	GList *children;
	
	c = cast(DflGtkContainer*)container;
	
	children = c.children;
	while(children)
	{
		child = cast(GtkWidget*)children.data;
		
		if(child is widget)
		{
			gtk_widget_unparent(widget);
			c.children = g_list_remove_link(c.children, children);
			g_list_free(children);
			break;
		}
		
		children = children.next;
	}
}


extern(C) void dflGtkContainer_forall(GtkContainer *container, gboolean include_internals,
	GtkCallback callback, gpointer callback_data)
{
	DflGtkContainer *c;
	GtkWidget *child;
	GList *children;
	c = cast(DflGtkContainer*)container;
	
	children = c.children;
	while(children)
	{
		child = cast(GtkWidget*)children.data;
		children = children.next;
		
		callback(child, callback_data);
	}
}


package:

GtkContainerClass* _parentclass = null;
GType _containertype = 0;

