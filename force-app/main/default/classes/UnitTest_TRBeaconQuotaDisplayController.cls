/**
*   {Purpose}  �  Unit Tests for TRBeaconQuotaDisplayController
*
*	{Code Covered}	- TRBeaconQuotaDisplayController.class
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20150318  	Andy Boettcher DCS		Created
*   =============================================================================
*/
@isTest
private class UnitTest_TRBeaconQuotaDisplayController {
	
	@isTest static void testController() {
		
		UnitTest_Test_Data.commitFPIApexSettings(true);

		Master_Test__c mtTest = new Master_Test__c();
		mtTest.Public_Test_Description__c = 'CLT_SOMETHING_ANOTHER';
		mtTest.Opportunity_Name__c = 'CLT_SOMETHING_ANOTHER';
		insert mtTest;

		Quota__c mtQuota = new Quota__c(Related_Test__c=mtTest.Id);
		mtQuota.Beacon_Condition__c = 'conditionsTestMethod';
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

		/************************************************/
		test.startTest();

		TRBeaconQuotaDisplayController clsBeaconNegative = new TRBeaconQuotaDisplayController(new ApexPages.StandardController(trCon2));
		List<TRBeaconQuotaDisplayController.hClsQuota> lstQuotaBad = clsBeaconNegative.lstQuotas;
		System.Assert(lstQuotaBad.size() == 1, 'Negative Test Case has Positive Results??!');

		TRBeaconQuotaDisplayController clsBeaconPositive = new TRBeaconQuotaDisplayController(new ApexPages.StandardController(trCon1));
		List<TRBeaconQuotaDisplayController.hClsQuota> lstQuotaGood = clsBeaconPositive.lstQuotas;
		System.Assert(lstQuotaGood.size() > 1, 'Positive Test Case has Negative Results??!');

		test.stopTest();
		/************************************************/

	}	
}