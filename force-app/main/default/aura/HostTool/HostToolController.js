/**
 * 09.20.2023	Sophia Murphy (Demand Chain)
 * 				Removed auto-refresh logic; added in just a general refresh button
 * 
 */
({
    doInit : function(component, event, helper) {
        helper.toggleSpinner(component, event);
    	helper.getUserSetting(component, event);
        helper.getMasterTestData(component, event);
    },
    refreshSession : function(component, event, helper){
        helper.toggleSpinner(component, event);
    	helper.getSessionRecords(component, event);
    	helper.getLatestDashboard(component, event);
    	helper.getCommunications(component, event);
    },
    refreshSessionDisplay : function(component, event, helper){
    	helper.toggleSpinner(component, event);
    	helper.getSessionRecordsDisplay(component, event);
    	helper.getCommunications(component, event);
    },
	openModal : function(component, event, helper) {
		helper.setRespondentRecord(component, event);
		var modal = component.find("RespondentModal");
		$A.util.removeClass(modal,"slds-hide");
	},
	closeModal : function(component, event, helper){
		helper.getLatestDashboard(component, event);
		var modal = component.find("RespondentModal");
		$A.util.addClass(modal,"slds-hide");
	},
	search : function(component, event, helper){
		helper.getRespondentSearch(component, event);
	},
	listviewchange : function(component, event, helper){
        helper.toggleSpinner(component, event);
		helper.setUserSetting(component, event);
		helper.getSessionRecordsDisplay(component, event);
	},
	emailRequest : function(component, event, helper){
		helper.sendEmailNotice(component, event);
	},
	clearMessage : function(component, event, helper){
		helper.clearMessage(component, event);
	},
	doRefresh : function(component, event, helper){
        helper.toggleSpinner(component, event);
		helper.getSessionRecordsDisplay(component, event);
	},
	/**autoRefreshUpdate : function(component, event, helper){
        helper.toggleSpinner(component, event);
		helper.getSessionRecordsDisplay(component, event);
	},*/
	clearSearch : function(component, event, helper){
		debugger;
		component.set("v.SearchRespondent", null);
		helper.getRespondentSearch(component, event);;
	},
	sortData : function(component, event, helper){
		helper.sortData(component, event);
	}
})