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
*   =============================================================================
*/
@isTest
private class UnitTest_cls_HostToolController {
	
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

		Contact con1 = UnitTest_Test_Data.BuildContact(1, userInfo.getUserId(), acctRespondent.Id, 'Adult-Respondent');
		insert con1;

		Contact con2 = UnitTest_Test_Data.BuildContact(2, userInfo.getUserId(), acctRespondent.Id, 'Adult-Respondent');
		insert con2;

		// Create Households
        Household__c hseSource = new Household__c();
        hseSource.MailingStreet__c = '123 MyStreet Road';
        hseSource.MailingState__c = 'MN';
        insert hseSource;

        Household_Contact__c hcSource = new Household_Contact__c();
        hcSource.Household__c=hseSource.Id;
        hcSource.Contact__c=con1.Id;
        insert hcSource;

		List<Session__c> lstInsertSessions = new List<Session__c>();
		Session__c seTest1 = new Session__c(Related_Test__c=mtTest.Id);
		seTest1.Name = 'Test Session 1';
		seTest1.Session_Start__c = System.Now();
		seTest1.Session_End__c = System.Now().addHours(1);
		insert seTest1;

		Session__c seTest2 = new Session__c(Related_Test__c=mtTest.Id);
		seTest2.Name = 'Test Session 2';
		seTest2.Session_Start__c = System.Now().addHours(1);
		seTest2.Session_End__c = System.Now().addHours(2);
		seTest2.Check_Amount__c = 42.00;
		lstInsertSessions.add(seTest2);
		insert seTest2;

		Session_Quota__c seQuota = new Session_Quota__c(Related_Session__c=seTest1.Id,Master_Quota__c=mtQuota.Id);
		insert seQuota;

		Test_Respondent__c trCon1 = new Test_Respondent__c(Master_Test__c=mtTest.Id, Respondent__c=con1.Id);
		trCon1.Check_Amount__c = 42.00;
		trCon1.Screener_Results__c = '[{"value":"1","key":"conditionsTraditional_Chicken_Noodle"},{"value":"0","key":"conditionsLight_Beef_Pot_Roast"},{"value":"1","key":"vlist"},{"value":"189.9134347445","key":"qtime"}]';
		insert trCon1;
		Test_Respondent__c trCon2 = new Test_Respondent__c(Master_Test__c=mtTest.Id, Respondent__c=con1.Id, Pair_Primary__c=trCon1.Id);insert trCon2;
		Test_Respondent__c trConDOT = new Test_Respondent__c(Master_Test__c=mtTest.Id,Check_Number__c='12345',Check_Amount__c=100);insert trConDOT;

		Test_Respondent_Quota__c trqCon1 = new Test_Respondent_Quota__c();
		trqCon1.Test_Respondent__c = trCon1.Id;
		trqCon1.Session_Quota__c = seQuota.Id;
		trqCon1.IsScheduled__c = TRUE;
		insert trqCon1;

		//Test_Respondent_Quota__c trqCon2 = new Test_Respondent_Quota__c();
		//trqCon2.Test_Respondent__c = trCon2.Id;
		//trqCon2.Session_Quota__c = seQuota.Id;
		//trqCon2.IsScheduled__c = TRUE;
		//insert trqCon2;

		/************************************************/
		test.startTest();

		HostToolController clsHost = new HostToolController();

		clsHost.idMasterTest = mtTest.Id;
		clsHost.idSession = null;
		clsHost.strRespSearch = '';

		clsHost.fillAllRespondentQuotas();

		clsHost.fillRespondentList();
		clsHost.idSession = seTest1.Id;
		clsHost.fillRespondentList();

		List<SelectOption> lstProjects = clsHost.lstProjects;
		List<SelectOption> lstSessions = clsHost.lstSessions;
		List<SelectOption> lstViewTypes = clsHost.lstViewTypes;
		Master_Test__c mtFieldSet = clsHost.mtFieldSet;


		clsHost.strRespSearch = 'John';
		clsHost.strViewType = 'Session View';
		clsHost.fillRespondentList();

		clsHost.strViewType = 'List View';
		clsHost.fillRespondentList();

		List<HostToolController.hClsQuota> lstQuotas = HostToolController.respondentQuota(trCon1.Id);
		for(HostToolController.hClsQuota qta : lstQuotas) {
			System.Assert(qta.key.length() > 0, 'key is not found!');
			System.Assert(qta.value.length() > 0, 'value is not found!');
		}

		HostToolController.saveRespondent(con1, trCon1, hseSource);

		// DOT Check Assign
		HostToolController.listDOTChecksForTest(clsHost.idMasterTest);
		HostToolController.updateTRWithDOTCheck(trConDOT.Id, trCon1.Id);

		// Printable View
		HostToolController clsHostSC = new HostToolController(new ApexPages.StandardController(mtTest));
		clsHostSC.idMasterTest = mtTest.Id;
		clsHostSC.renderPrintable();

		test.stopTest();
		/************************************************/

	}
	
}