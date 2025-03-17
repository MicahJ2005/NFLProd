/**
*   {Purpose}  �  Coverage for the Master Test's Session Manager
*
*	{Code Covered}	- SessionManagerController
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20140609  	Andy Boettcher DCS		Created
*   =============================================================================
*/
@isTest
private class UnitTest_cls_SessionManagerController {
	
	@isTest static void testController() {
		
		UnitTest_Test_Data.commitFPIApexSettings();

		Master_Test__c mtTest = new Master_Test__c();
		mtTest.Public_Test_Description__c = 'Test Master Test / Host Tool';
		insert mtTest;

		Quota__c mtQuota = new Quota__c(Related_Test__c=mtTest.Id);
		mtQuota.Beacon_Condition__c = 'conditionsTestMethod';
		insert mtQuota;

		/**********************************************/
		test.startTest();

		SessionManagerController clsSM = new SessionManagerController(new ApexPages.StandardController(mtTest));

		// List all Sessions - should be zero
		System.Assert(clsSM.lstSessions.size() == 0, 'There are sessions when none should exist!');

		// Create New Session
		clsSM.saveSession();
		System.Assert(clsSM.lstSessions.size() == 1, 'There are no sessions when one should exist!');

		// Copy Session - BEFORE
		clsSM.idSessionTemplate = clsSM.lstSessions[0].Id;
		clsSM.bolCreateBefore = true;
		clsSM.resetSession();
		clsSM.saveSession();
		System.Assert(clsSM.lstSessions.size() == 2, 'There are no sessions when two should exist!');

		// Copy Session - AFTER
		clsSM.idSessionTemplate = clsSM.lstSessions[0].Id;
		clsSM.bolCreateBefore = false;
		clsSM.resetSession();
		clsSM.saveSession();
		System.Assert(clsSM.lstSessions.size() == 3, 'There are no sessions when three should exist!');

		clsSM.idSessionEdit = clsSM.lstSessions[0].Id;
		clsSM.resetSession();
		clsSM.saveSession();

		clsSM.idSessionEdit = clsSM.lstSessions[0].Id;
		clsSM.resetSession();
		clsSM.lstMasterQuotas[0].bolChecked = false;
		clsSM.saveSession();




		test.stopTest();
		/**********************************************/

	}
	
}