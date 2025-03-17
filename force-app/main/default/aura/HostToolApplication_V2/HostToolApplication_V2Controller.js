({
	openHelpModal : function(component, event, helper) {
		var modal = component.find("HelperModal");
		$A.util.removeClass(modal,"slds-hide");
	},
	closeHelpModal : function(component, event, helper){
		var modal = component.find("HelperModal");
		$A.util.addClass(modal,"slds-hide");
	},
	sendBadBehaviorEmail : function(component, event, helper){
		helper.sendBadBehaviorEmail(component, event);
	}
})