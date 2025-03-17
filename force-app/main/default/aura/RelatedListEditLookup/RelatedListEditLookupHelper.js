({
	handleSubmit : function(component, event) {
        debugger;
        var parentField = component.get("v.field");
        var newParentId = event.getParam("fields")[parentField].value;
        var evt = $A.get('e.c:RelatedListEditLookupEvent');
        evt.setParams({
            recordId : component.get("v.recordId")
            ,applyAll : component.get("v.applyAll")
            ,relationshipName : parentField
            ,newParentId : newParentId
        });
        evt.fire();
        component.set("v.isOpen", false); 
        component.find("popuplib").notifyClose();
    }
})