@isTest
private class UnitTest_cls_HostToolLightning {
	
	@isTest static void testController() {
		
		UnitTest_Test_Data.commitFPIApexSettings(true); 
        

		HostToolEmailSettings__c csHTEmail = UnitTest_Test_Data.BuildHostEmailSetting('done');
		insert csHTEmail;

		List<HostToolColorCoding__c> lstHTCC = UnitTest_Test_Data.BuildHostColor();
		insert lstHTCC;

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

		Test_Respondent_Quota__c trqCon1 = new Test_Respondent_Quota__c();
		trqCon1.Test_Respondent__c = trCon1.Id;
		trqCon1.Session_Quota__c = seQuota.Id;
		trqCon1.IsScheduled__c = TRUE;
		insert trqCon1;

		List<Test_Respondent__c> child = new List<Test_Respondent__c>();

		Test.startTest();
			HostToolLightning.CheckinRespondent('Pending', '123456', trCon1.Id, child);
			HostToolLightning.CreateAllergyCase(trCon1.Id);
			HostToolLightning.ScheduledPeelOffs(mtTest.Id, con1.Id, seTest2.Id);
			HostToolLightning.fillRespondentList(seTest1.Id, mtTest.Id, '', 'Session View');
			HostToolLightning.getMasterTest();
			HostToolLightning.getPeelOffs(mtTest.Id);
			HostToolLightning.getQuotaInfo(trCon1.Id);
			HostToolLightning.getStatusValues();
			HostToolLightning.getcomms(mtTest.Id, seTest1.Id);
			HostToolLightning.listDOTChecksForTest(mtTest.Id);
			HostToolLightning.manageUserViewPreference();
			HostToolLightning.respondentQuota(trCon1.Id);
			HostToolLightning.sendemailMessage('done', seTest1.Id);
			HostToolLightning.upcomingTest(con1.Id, seTest1.Id);
			HostToolLightning.updateTRWithDOTCheck(trConDOT.Id, trCon2.Id);
			HostToolLightning.updateTrackerStats(mtTest.Id);
			HostToolLightning.updateUserViewPreference('Session View');
		Test.stopTest();
	}
}