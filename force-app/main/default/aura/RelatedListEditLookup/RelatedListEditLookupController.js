({
    doInit : function(component, event, helper){
        var fields = [];
        fields.push(component.get("v.field"));
        component.set("v.fields", fields);
    },
	handleSubmit : function(component, event, helper) {
        helper.handleSubmit(component, event);
    },
   	handleCancel : function(component) {
       component.set("v.isOpen", false);
       component.find("popuplib").notifyClose();
    }
})