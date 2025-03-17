/**
*   {Purpose}  �  TODO:  Provide coverage for the Host Tool and Host Tool Printable
*
*	{Code Covered}	- HostToolController
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
*	TODO 		Need to complete this UT with Assertions and User Context
*   20180920    Sophia Murphy (Demand Chain)
*               Getting SOQL errors, "crunched" up inserts to insert sobject lists.
*   =============================================================================
*/
@isTest
private class UnitTest_cls_HostToolBulkController {
	
	@isTest static void testController() {
		
		UnitTest_Test_Data.commitFPIApexSettings(true);

		Master_Test__c mtTest = new Master_Test__c();
		mtTest.Public_Test_Description__c = 'CLT_SOMETHING_ANOTHER';
		mtTest.Opportunity_Name__c = 'CLT_SOMETHING_ANOTHER';
		insert mtTest;

		Quota__c mtQuota = new Quota__c(Related_Test__c=mtTest.Id);
		mtQuota.Beacon_Condition__c = 'conditionsTest';
		insert mtQuota;

		Account acctRespondent = UnitTest_Test_Data.buildTestAccount('Respondent Master Account',userInfo.getUserId());
		insert acctRespondent;

        //to help with SOQL limits, inserting in bulk...
        List<sObject> sobjInsert1 = new List<sObject>();

        Contact con1 = UnitTest_Test_Data.BuildContact(1, userInfo.getUserId(), acctRespondent.Id, 'Adult-Respondent');
		//insert con1;
        sobjInsert1.add(con1);

		Contact con2 = UnitTest_Test_Data.BuildContact(2, userInfo.getUserId(), acctRespondent.Id, 'Adult-Respondent');
		//insert con2;
        sobjInsert1.add(con2);

		// Create Households
        Household__c hseSource = new Household__c();
        hseSource.MailingStreet__c = '123 MyStreet Road';
        hseSource.MailingState__c = 'MN';
        //insert hseSource;
        sobjInsert1.add(hseSource);
        insert sobjInsert1;


        //to help with SOQL limits, inserting in bulk...
        List<sObject> sobjInsert2 = new List<sObject>();

        Household_Contact__c hcSource = new Household_Contact__c();
        hcSource.Household__c=hseSource.Id;
        hcSource.Contact__c=con1.Id;
        //insert hcSource;
        sobjInsert2.add(hcSource);

		//List<Session__c> lstInsertSessions = new List<Session__c>();
		Session__c seTest1 = new Session__c(Related_Test__c=mtTest.Id);
		seTest1.Name = 'Test Session 1';
		seTest1.Session_Start__c = System.Now();
		seTest1.Session_End__c = System.Now().addHours(1);
		//insert seTest1;
        sobjInsert2.add(seTest1);

		Session__c seTest2 = new Session__c(Related_Test__c=mtTest.Id);
		seTest2.Name = 'Test Session 2';
		seTest2.Session_Start__c = System.Now().addHours(1);
		seTest2.Session_End__c = System.Now().addHours(2);
		seTest2.Check_Amount__c = 42.00;
		//lstInsertSessions.add(seTest2);
		//insert seTest2;
        sobjInsert2.add(seTest2);

        insert sobjInsert2;

        //to help with SOQL limits, inserting in bulk...
        List<sObject> sobjInsert3 = new List<sObject>();

		Session_Quota__c seQuota = new Session_Quota__c(Related_Session__c=seTest1.Id,Master_Quota__c=mtQuota.Id);
		//insert seQuota;
        sobjInsert3.add(seQuota);

		Test_Respondent__c trCon1 = new Test_Respondent__c(Master_Test__c=mtTest.Id, Respondent__c=con1.Id);
		trCon1.Check_Amount__c = 42.00;
		trCon1.Screener_Results__c = '[{"value":"1","key":"conditionsTraditional_Chicken_Noodle"},{"value":"0","key":"conditionsLight_Beef_Pot_Roast"},{"value":"1","key":"vlist"},{"value":"189.9134347445","key":"qtime"}]';
		//insert trCon1;
        sobjInsert3.add(trCon1);
        insert sobjInsert3;

        //to help with SOQL limits, inserting in bulk...
        List<sObject> sobjInsert4 = new List<sObject>();

		Test_Respondent__c trCon2 = new Test_Respondent__c(Master_Test__c=mtTest.Id, Respondent__c=con1.Id, Pair_Primary__c=trCon1.Id);
        //insert trCon2;
        sobjInsert4.add(trCon2);

		Test_Respondent__c trConDOT = new Test_Respondent__c(Master_Test__c=mtTest.Id,Check_Number__c='12345',Check_Amount__c=100);
        //insert trConDOT;
        sobjInsert4.add(trConDOT);

		Test_Respondent_Quota__c trqCon1 = new Test_Respondent_Quota__c();
		trqCon1.Test_Respondent__c = trCon1.Id;
		trqCon1.Session_Quota__c = seQuota.Id;
		trqCon1.IsScheduled__c = TRUE;
		//insert trqCon1;
        sobjInsert4.add(trqCon1);
        insert sobjInsert4;

		Test_Respondent_Quota__c trqCon2 = new Test_Respondent_Quota__c();
		trqCon2.Test_Respondent__c = trCon2.Id;
		trqCon2.Session_Quota__c = seQuota.Id;
		trqCon2.IsScheduled__c = TRUE;
		insert trqCon2;

		/************************************************/
		test.startTest();

		HostToolBulkController clsHost = new HostToolBulkController();
		HostToolBulkController.testedStatusOptions();
		HostToolBulkController.lstViewTypes();
		HostToolBulkController.lstProjects();
		HostToolBulkController.mtFieldSet(mtTest.Id);
		HostToolBulkController.lstSessions(mtTest.Id);
		HostToolBulkController.trackerStats(mtTest.Id);

		HostToolBulkController.fillRespondentList(mtTest.Id, null, 'List View', '');
		HostToolBulkController.fillRespondentList(mtTest.Id, seTest1.Id, 'List View', '');
		HostToolBulkController.fillRespondentList(mtTest.Id, seTest1.Id, 'List View', '1');

		HostToolBulkController.fillRespondentList(mtTest.Id, null, 'Session View', '');
		HostToolBulkController.fillRespondentList(mtTest.Id, seTest1.Id, 'Session View', '');
		HostToolBulkController.fillRespondentList(mtTest.Id, seTest1.Id, 'Session View', '1');

		List<HostToolBulkController.hClsQuota> lstQuotas = HostToolBulkController.respondentQuota(trCon1.Id);

		HostToolBulkController.saveRespondent(con1, trCon1, hseSource);

		// DOT Check Assign
		HostToolBulkController.listDOTChecksForTest(mtTest.Id);
		HostToolBulkController.updateTRWithDOTCheck(trConDOT.Id, trCon1.Id);

		test.stopTest();
		/************************************************/

	}
	
}