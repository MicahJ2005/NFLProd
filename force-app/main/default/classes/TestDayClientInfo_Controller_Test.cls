@isTest
private class TestDayClientInfo_Controller_Test {
	@isTest
	static void doNothing(){
		TestDayClientInfo_Controller.doNothing();
	}
	/**
	@testSetup static void SetupDataForTest(){
		UnitTest_Test_Data.commitFPIApexSettings();

		Master_Test__c mtTest = new Master_Test__c();
		mtTest.Public_Test_Description__c = 'CLT_SOMETHING_ANOTHER';
		mtTest.Opportunity_Name__c = 'CLT_SOMETHING_ANOTHER';
		insert mtTest;

		Account acctRespondent = UnitTest_Test_Data.buildTestAccount('Respondent Master Account',userInfo.getUserId());
		insert acctRespondent;

		Contact con1 = UnitTest_Test_Data.BuildContact(1, userInfo.getUserId(), acctRespondent.Id, 'Adult-Respondent');
		insert con1;

		Contact con2 = UnitTest_Test_Data.BuildContact(2, userInfo.getUserId(), acctRespondent.Id, 'Adult-Respondent');
		insert con2;

		Account acctTestingLoc = UnitTest_Test_Data.buildTestAccount('Local Testing Location',userInfo.getUserId());
		acctTestingLoc.Driving_Directions_and_Hotel_Information__c = '1234 abc st';
		acctTestingLoc.Shipping_Information__c = 'Send it to the back dock';

		insert acctTestingLoc;

		List<Session__c> lstInsertSessions = new List<Session__c>();
		Session__c seTest1 = new Session__c();
		seTest1.Related_Test__c = mtTest.Id;
		seTest1.Name = 'Test Session 1';
		seTest1.Session_Start__c = System.Now();
		seTest1.Session_End__c = System.Now().addHours(1);

		Session__c seTest2 = new Session__c();
		seTest2.Related_Test__c = mtTest.Id;
		seTest2.Name = 'Test Session 2';
		seTest2.Session_Start__c = System.Now().addHours(1);
		seTest2.Session_End__c = System.Now().addHours(1);

		Session__c seTest3 = new Session__c();
		seTest3.Related_Test__c = mtTest.Id;
		seTest3.Name = 'Test Session 3';
		seTest3.Session_Start__c = System.Now().addHours(24);
		seTest3.Session_End__c = System.Now().addHours(25);

		Session__c seTest4 = new Session__c();
		seTest4.Related_Test__c = mtTest.Id;
		seTest4.Name = 'Test Session 3';
		seTest4.Session_Start__c = System.Now().addHours(25);
		seTest4.Session_End__c = System.Now().addHours(26);
		
		lstInsertSessions.add(seTest1);
		lstInsertSessions.add(seTest2);
		lstInsertSessions.add(seTest3);
		lstInsertSessions.add(seTest4);

		insert lstInsertSessions;

		Id recordTId = Schema.SObjectType.Task_Queue__c.getRecordTypeInfosByName().get('Fielding Test Summary').getRecordTypeId();
		Task_Queue__c tq = new Task_Queue__c();
		tq.RecordTypeId = recordTId;
		tq.Master_Test__c = mtTest.Id;
		tq.Location__c = acctTestingLoc.Id;
		insert tq;
	}
	@isTest static void test_ShippingInfo() {
		Task_Queue__c testTQ = new Task_Queue__c();
		testTQ = [SELECT Id FROM Task_Queue__c LIMIT 1];
		Test.startTest();
			PageReference pageRef = Page.TestDayClientInfo;
			Test.setCurrentPage(pageRef);
			ApexPages.StandardController sc = new ApexPages.StandardController(testTQ);
			TestDayClientInfo_Controller tdcc = new TestDayClientInfo_Controller(sc);
		Test.stopTest();
	}
	*/
}