({
	handleSubmit : function(component, event) {
        event.preventDefault();
        var parentField = component.get("v.field");
        var newParentId = event.getParam("fields")[parentField];
        var evt = $A.get('e.c:LookupEvent');
        evt.setParams({
            recordId : component.get("v.recordId")
            ,applyAll : component.get("v.applyAll")
            ,relationshipName : parentField
            ,newParentId : newParentId
            ,status : 'SUCCESS'
        });
        evt.fire();
    },
    handleCancel : function(component){
        var evt = $A.get('e.c:LookupEvent');
        evt.setParams({
            status : 'CANCEL'
        });
        evt.fire();
    }
})