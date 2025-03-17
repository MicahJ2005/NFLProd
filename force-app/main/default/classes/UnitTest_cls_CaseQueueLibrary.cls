/**
*   {Purpose}  �  Unit Tests for Task_Queue__c
*
*	{Code Covered}	- CaseQueueLibrary.cls, CaseQueueConvertPCC.page
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20140822  	Andy Boettcher DCS		Created
*   =============================================================================
*/
@isTest
private class UnitTest_cls_CaseQueueLibrary {

	@testSetup static void setupTestData() {

		UnitTest_Test_Data.commitFPIApexSettings();

		Account acct = new Account(Name='Test Account'); insert acct;
		Contact cont = new Contact(Lastname='test', AccountId=acct.Id); insert cont;

		Opportunity opp = UnitTest_Test_Data.BuildOpportunity(acct.Id, 'Consumer Research Opportunity', 'Initiate/Open'); insert opp;

		Master_Test__c mt = new Master_Test__c();
		mt.Opportunity__c = opp.Id;
		mt.Public_Test_Description__c = 'test';
		insert mt;

		Task_Queue__c tq = new Task_Queue__c();
		tq.Master_Test__c = mt.Id;
		tq.Amount__c = 42;
		tq.Status__c = 'Additive';
		tq.Type__c = 'FPI Driven';
		tq.Description__c = 'Test Description';
		tq.Contact_Name__c = cont.Id;
		insert tq;

		Task tsk = new Task();
		tsk.WhatId = tq.Id;
		tsk.Ease_Of_Understanding__c = '1';
		tsk.Enthusiasm__c = '1';
		tsk.Creativity_Score__c = 1;
		tsk.Notes_On_Restriction__c = 'Test Test Test';
		insert tsk;

	}
	/** REMOVED - PCCs are no longer used
	@isTest static void testPCCConvertController() {
		
		Master_Test__c objMT = [SELECT Id, Opportunity__c, Public_Test_Description__c FROM Master_Test__c LIMIT 1];
		Task_Queue__c objTQ = [SELECT Id, Master_Test__c, Amount__c, Status__c, Type__c, Description__c, Contact_Name__c FROM Task_Queue__c LIMIT 1];

		test.startTest();

			Test.setCurrentPage(Page.CaseQueueConvertPCC);

			// Run as admin user
			CaseQueueLibrary clsCQL = new CaseQueueLibrary(new Apexpages.standardController(objTQ));
			clsCQL.convertToOppPCC();

		test.stopTest();

		List<Project_Change_Control__c> lstPCC = [SELECT Id FROM Project_Change_Control__c];
		System.Assert(lstPCC.size() > 0, 'PCC was not created properly!');

	}*/

	@isTest static void testArticulationConversion() {

		Task objTask = [SELECT Id, WhatId, Final_Articulation_Score__c, Creativity_Score__c, LastModifiedDate, Notes_on_Restriction__c FROM Task LIMIT 1];

		test.startTest();

			PageReference prTest = Page.CaseQueueConvertArticulation;
			prTest.getParameters().put('id', objTask.Id);
			Test.setCurrentPage(prTest);

			CaseQueueLibrary clsCQL = new CaseQueueLibrary(new ApexPages.standardController(objTask));
			clsCQL.convertToArticulation();

		test.stopTest();

	}
	
}