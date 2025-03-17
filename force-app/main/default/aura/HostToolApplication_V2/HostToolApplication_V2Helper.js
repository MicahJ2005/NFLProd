({
    sendBadBehaviorEmail : function(component, event){
        var action = component.get("c.sendBadBehaviorMessage");
        action.setParams({masterTestId : component.get("v.MasterTestId"), emailBody : component.get("v.badBehaviorText")});
        action.setCallback(this, function(response){
            var state = response.getState();
            if(component.isValid() && state === "SUCCESS"){
                var modal = component.find("HelperModal");
		        $A.util.addClass(modal,"slds-hide");
                component.set("v.successMessages", ['Bad Behavior Reported']);     
            }               
        });
        $A.enqueueAction(action);
    }
})