public class QuickTaskController {

/**
*   {Purpose}  �  PURPOSE OF CLASS
*                 
*   {Function}  � DESCRIBE PUBLIC FUNCTIONS
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20140212  	Andy Boettcher DCS    	Created
*   =============================================================================
*/
	public Task tskNew {get;set;}
	public Task tskFollowup {get;set;}

	///////////////////////////////////
	// Constructors
	///////////////////////////////////
	public QuickTaskController() {
		tskNew = new Task();
		tskNew.RecordTypeId = UtilityMethods.RECORDTYPE_ID('Task', 'Touch Point Process');
		tskNew.Status = 'Completed';
		tskNew.Subject = '';
		tskNew.ActivityDate = System.Today();
		tskNew.OwnerId = UserInfo.getUserId();
		tskNew.Description = '';
		tskNew.WhoId = apexpages.currentPage().getParameters().get('who');
		tskNew.WhatId = apexpages.currentPage().getParameters().get('what');
		
		tskFollowup = new Task();
		tskFollowup.RecordTypeId = UtilityMethods.RECORDTYPE_ID('Task', 'Touch Point Process');
		tskFollowup.Status = 'Not Started';
		tskFollowup.Subject = '';
		tskFollowup.ActivityDate = System.Today().addDays(7);
		tskFollowup.OwnerId = UserInfo.getUserId();
		tskFollowup.Description = '';
		tskFollowup.WhoId = apexpages.currentPage().getParameters().get('who');
		tskFollowup.WhatId = apexpages.currentPage().getParameters().get('what');
	}

	///////////////////////////////////
	// Action Methods
	///////////////////////////////////
	public PageReference cancel() {

		return returnUserToHome();

	}

	public PageReference saveTask() {

		if(!verifyTaskFields()) {
        	return null;
        }
        
        List<Task> lstTasksToInsert = new List<Task>();
        lstTasksToInsert.add(tskNew);
        lstTasksToInsert.add(tskFollowup);

        try {
        	insert lstTasksToInsert;
    	} catch(Exception ex) {
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error: There was an error '));
    	}

		return returnUserToHome();

	}

	private Boolean verifyTaskFields() {

		Boolean retVal = true;

		String strFUDescription = tskFollowup.Description;

		if(this.tskNew.Subject == null || this.tskNew.OwnerId == null || this.tskNew.ActivityDate == null || this.tskNew.Description == null) {
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error: You are missing information from the main task on this page, please review your input!'));
        	retVal = false;
		}

		if(this.tskFollowup.Subject == null || this.tskFollowup.OwnerId == null || this.tskFollowup.ActivityDate == null || this.tskFollowup.Description == null) {
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error: You are missing information from the followup task on this page, please review your input!'));
        	retVal = false;
		}

		return retVal;

	}

	private PageReference returnUserToHome() {

		PageReference prRef = new PageReference('/');
		prRef.setRedirect(true);
		return prRef;

	}

}