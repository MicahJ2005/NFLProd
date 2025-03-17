/**
*   {Purpose}  �  TODO:  Unit Test Coverage for TestFillWeightingController
*
*	{Code Covered}	- TestFillWeightingController
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20140603  	Andy Boettcher DCS		Created
*   =============================================================================
*/
@isTest
private class UnitTest_cls_TestFillWeightingController {
	
	@isTest static void testWeightingController() {
		
		Master_Test__c mtTest = new Master_Test__c();
		insert mtTest;

		List<Quota__c> lstQuotas = new List<Quota__c>();
		lstQuotas.add(new Quota__c(Related_Test__c=mtTest.Id,Quota_Summary__c='Test 1',Beacon_Condition__c='conditionsTestMethod1'));
		lstQuotas.add(new Quota__c(Related_Test__c=mtTest.Id,Quota_Summary__c='Test 2',Beacon_Condition__c='conditionsTestMethod2'));
		lstQuotas.add(new Quota__c(Related_Test__c=mtTest.Id,Quota_Summary__c='Test 3',Beacon_Condition__c='conditionsTestMethod3'));
		lstQuotas.add(new Quota__c(Related_Test__c=mtTest.Id,Quota_Summary__c='Test 4',Beacon_Condition__c='conditionsTestMethod4'));
		lstQuotas.add(new Quota__c(Related_Test__c=mtTest.Id,Quota_Summary__c='Test 5',Beacon_Condition__c='conditionsTestMethod5'));
		insert lstQuotas;

		test.startTest();

		TestFillWeightingController clsWeight = new TestFillWeightingController(new ApexPages.StandardController(mtTest));
		System.Assert(clsWeight.lstQuotas.size() == 5, 'Quotas were not inserted correctly!');

		for(Quota__c quota : clsWeight.lstQuotas) {
			quota.Fill_Weighting__c = 1;
		}

		clsWeight.saveWeighting();

		test.stopTest();

	}
	
}