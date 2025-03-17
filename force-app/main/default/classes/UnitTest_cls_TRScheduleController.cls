/**
*   {Purpose}  �  Provides Unit Test Coverage of Classes and Pages
*
*	{Code Covered}	- TestRespondentSchedule.page and TestRespondentScheduleCntrl.cls
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20140804  	Andy Boettcher DCS		Created
*   =============================================================================
*/
@isTest
private class UnitTest_cls_TRScheduleController {
	
	@isTest static void testController() {
		
		UnitTest_Test_Data.commitFPIApexSettings(true);

		UtilityMethods.bolPreventHouseholdSQS = true;
		UtilityMethods.bolPreventSQSQS = true;
		UtilityMethods.bolPreventTRQSQS = true;
		UtilityMethods.bolPreventTRSQS = true;
		UtilityMethods.bolPreventContactSQS = true;

        User testUser = UnitTest_Test_data.buildTestUser(1, 'System Administrator');
        insert testUser;
        
		Master_Test__c mtTest = new Master_Test__c();
		mtTest.Public_Test_Description__c = 'CLT_SOMETHING_ANOTHER';
		mtTest.Opportunity_Name__c = 'CLT_SOMETHING_ANOTHER';
		insert mtTest;

		Quota__c mtQuota = new Quota__c(Related_Test__c=mtTest.Id,IsTrackingOnly__c=true);
		mtQuota.Beacon_Condition__c = 'conditionsTestMethod';
		insert mtQuota;
        
        Quota__c mtQuota2 = new Quota__c(Related_Test__c=mtTest.Id,IsTrackingOnly__c=false);
        mtQuota2.Beacon_Condition__c = 'conditionsTestMethod2';
		insert mtQuota2;

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
		//Need to insert this record 1-off; so it can be referenced below
		insert seTest1;
        //lstInsertSessions.add(seTest1);

		Session__c seTest2 = new Session__c(Related_Test__c=mtTest.Id);
		seTest2.Name = 'Test Session 2';
		seTest2.Session_Start__c = System.Now().addHours(1);
		seTest2.Session_End__c = System.Now().addHours(2);
		seTest2.Linked_Session__c = seTest1.Id;
		seTest2.IsArticulationNeeded__c = true;
		insert seTest2;
        //lstInsertSessions.add(seTest2);
        //insert lstInsertSessions;

        List<Session_Quota__c> lstInsertSessQuote = new List<Session_Quota__c>();
		Session_Quota__c seQuota = new Session_Quota__c(Related_Session__c=seTest1.Id,Master_Quota__c=mtQuota.Id);
		//insert seQuota;
        lstInsertSessQuote.add(seQuota);
        
        Session_Quota__c seQuota2 = new Session_Quota__c(Related_Session__c=seTest1.Id,Master_Quota__c=mtQuota2.Id);
		//insert seQuota2;
        lstInsertSessQuote.add(seQuota2);
        insert lstInsertSessQuote;

		Test_Respondent__c trCon1 = new Test_Respondent__c(Master_Test__c=mtTest.Id, Respondent__c=con1.Id);
		trCon1.Screener_Results__c = '[{"value":"1","key":"conditionsTraditional_Chicken_Noodle"},{"value":"0","key":"conditionsLight_Beef_Pot_Roast"},{"value":"1","key":"vlist"},{"value":"189.9134347445","key":"qtime"}]';
		insert trCon1;
        
		Test_Respondent__c trCon2 = new Test_Respondent__c(Master_Test__c=mtTest.Id, Respondent__c=con2.Id, Pair_Primary__c=trCon1.Id);
        insert trCon2;

		Test_Respondent_Quota__c trqCon1 = new Test_Respondent_Quota__c();
		trqCon1.Test_Respondent__c = trCon1.Id;
		trqCon1.Session_Quota__c = seQuota.Id;
		trqCon1.IsScheduled__c = TRUE;
		insert trqCon1;

		/************************************************/
		test.startTest();

		TestRespondentScheduleCntrl clsSchedule = new TestRespondentScheduleCntrl(new ApexPages.StandardController(trCon1));

		clsSchedule.idRespondent = trCon1.Id;
		clsSchedule.idMasterTest = mtTest.Id;
		//clsSchedule.idSession = seQuota.Id;

		List<TestRespondentScheduleCntrl.hClsSession> lstSessions = clsSchedule.lstSessions;
        clsSchedule.idSession = lstSessions[0].ses.Id;
        
        clsSchedule.fillQuotas();
        List<TestRespondentScheduleCntrl.hClsQuota> lstHard = clsSchedule.lstHard;
        List<TestRespondentScheduleCntrl.hClsQuota> lstSoft = clsSchedule.lstSoft;
        
        for(TestRespondentScheduleCntrl.hClsQuota cQ : lstHard) {
            cq.bolChecked = true;
        }
        
        for(TestRespondentScheduleCntrl.hClsQuota cQ : lstSoft) {
            cq.bolChecked = true;
        }

		// Round 1
		clsSchedule.scheduleRespondent();

		// Round 2
		//clsSchedule.scheduleRespondent();		

		test.stopTest();
		/************************************************/


	}
	
}