/**
*   {Purpose}  �  Provide Test Coverage for QuotaGroupVisualizerController
*
*	{Code Covered}	- QuotaGroupVisualizerController
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20140908  	Andy Boettcher DCS		Created
*   =============================================================================
*/
@isTest
private class UnitTest_cls_QuotaGroupVisualizerCtrlr {
	
	@isTest static void testController() {
		
		UnitTest_Test_Data.commitFPIApexSettings();

		Master_Test__c mtTest = new Master_Test__c();
		mtTest.Public_Test_Description__c = 'Test Master Test';
		insert mtTest;

		Quota__c mtQuota = new Quota__c(Related_Test__c=mtTest.Id);
		mtQuota.Beacon_Condition__c = 'conditionsTestMethod';
		insert mtQuota;

		Session__c seTest = new Session__c(Related_Test__c=mtTest.Id);
		seTest.Name = 'Test Session';
		seTest.Session_Start__c = System.Now();
		seTest.Session_End__c = System.Now().addHours(1);
		insert seTest;

		Session_Quota__c sqTest = new Session_Quota__c();
		sqTest.Master_Quota__c = mtQuota.Id;
		sqTest.Related_Session__c = seTest.Id;
		insert sqTest;

		test.startTest();

		QuotaGroupVisualizerController clsQG = new QuotaGroupVisualizerController(new ApexPages.standardController(mtTest));
		clsQG.saveQuotas();

	}
	
}