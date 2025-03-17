/**
 * 09.20.2023	Sophia Murphy (Demand Chain)
 * 				Removed auto-refresh logic; added in just a general refresh button
 * 08.20.2024	Sophia Murphy (Demand Chain)
 * 				Commented out Tested Goals
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
    	helper.getLatestDashboardMT(component, event);
    	//helper.getTestedGoals(component, event);
    	helper.getCommunications(component, event);
    },
    refreshSessionDisplay : function(component, event, helper){
    	helper.toggleSpinner(component, event);
    	helper.getSessionRecordsDisplay(component, event);
    	helper.getLatestDashboard(component, event);
    	helper.getCommunications(component, event);
    },
	handleModalChange : function(component, event, helper) {
		if (!component.get("v.modalOpen")) {
			helper.getSessionRecordsDisplay(component, event);
			//We don't want to refresh the stats with each click - takes too long
			//helper.getLatestDashboard(component, event);
			//helper.getLatestDashboardMT(component, event);
			//helper.getTestedGoals(component, event);
			helper.toggleSpinner(component, event);
		}
		
	},
	openModal : function(component, event, helper) {
		helper.setRespondentRecord(component, event);
		debugger;
		//var modal = component.find("RespondentModal");
		//$A.util.removeClass(modal,"slds-hide");
		component.set("v.modalOpen", true);
	},
	closeModal : function(component, event, helper){
		debugger;
    	//helper.getSessionRecordsDisplay(component, event);
		//helper.getLatestDashboard(component, event);
		//helper.getLatestDashboardMT(component, event);
    	//helper.getTestedGoals(component, event);
		//this.doRefresh(component, event);
		//var modal = component.find("RespondentModal");
		//$A.util.addClass(modal,"slds-hide");
		component.set("v.modalOpen", false);
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
		component.set("v.successMessages", []);
	},
	clearMessageDelayed : function(component, event, helper){
		helper.clearMessageDelayed(component, event);
	},
	doRefresh : function(component, event, helper){
        helper.toggleSpinner(component, event);
		helper.getSessionRecordsDisplay(component, event);
	},
	doStatsRefresh : function(component, event, helper){
		helper.getLatestDashboard(component, event);
		helper.getLatestDashboardMT(component, event);
    	//helper.getTestedGoals(component, event);
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
	},
	toggleToolTip : function(component, event, helper) {
		var toolTipComponent = document.getElementById(event.target.name);
    	$A.util.toggleClass(toolTipComponent, "slds-hide");
	}
})