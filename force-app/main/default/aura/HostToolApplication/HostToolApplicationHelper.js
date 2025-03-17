({
	sendEmailNotice : function(component, event){
        var emailType = event.currentTarget.getAttribute('data-type');
        var whatId = event.currentTarget.getAttribute('data-whatId');
        console.log('emailType: ' + emailType);
        var action = component.get("c.sendemailMessage");
        action.setParams({emailType : emailType, whatId : whatId});
        action.setCallback(this, function(response){
            component.set("v.message", response.getReturnValue());           
        });
        $A.enqueueAction(action);
    }
})