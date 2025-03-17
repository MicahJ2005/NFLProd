({
	emailRequest : function(component, event, helper){
		helper.sendEmailNotice(component, event);
	},
    openHelpModal : function(component, event, helper) {
		var modal = component.find("HelperModal");
		$A.util.removeClass(modal,"slds-hide");
	},
	closeHelpModal : function(component, event, helper){
		var modal = component.find("HelperModal");
		$A.util.addClass(modal,"slds-hide");
	}
})