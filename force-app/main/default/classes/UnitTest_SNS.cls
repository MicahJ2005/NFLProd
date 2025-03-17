@isTest
public class UnitTest_SNS {

	@testSetup
	static void testDataSetup() {
		UnitTest_Test_Data.commitFPIApexSettings(true);

		//User testuser = UnitTest_Test_data.buildTestUser(1, 'System Administrator');
        //insert testuser;
        
        //Account testAccountR = UnitTest_Test_data.buildTestAccount('Respondent Master Account', testUser.Id);
        //insert testAccountR;
        
        //FPI_AppSettings__c testAppSetting1 = UnitTest_Test_data.BuildFPI_AppSettings(testAccountR.Id, 'ID_RespondentAccount');
        //insert testAppSetting1;
        
        //FPI_AppSettings__c testAppSetting2 = UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactBusiness', 'Eurofins Client Contact', 'Contact');
        //insert testAppSetting2;
        
        //FPI_AppSettings__c testAppSetting3 = UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactRespondentAdult', 'Adult-Respondent', 'Contact');
        //insert testAppSetting3;

	}

    @isTest
    static void testSNSSuccess() {

        Test.setMock(HttpCalloutMock.class, new UnitTest_SNSSuccess_MOCK());
        
        test.startTest();
        
        Master_Test__c mtTest = new Master_Test__c();
		mtTest.Public_Test_Description__c = 'CLT_SOMETHING_ANOTHER';
		mtTest.Opportunity_Name__c = 'CLT_SOMETHING_ANOTHER';
		insert mtTest;

		Account acctRespondent = UnitTest_Test_Data.buildTestAccount('Respondent Master Account',userInfo.getUserId());
		insert acctRespondent;

		Contact con1 = UnitTest_Test_Data.BuildContact(1, userInfo.getUserId(), acctRespondent.Id, 'Adult-Respondent');
		insert con1;
        
        test.stopTest();
        
    }
    
    @isTest
    static void testSNSFailure() {
        Test.setMock(HttpCalloutMock.class, new UnitTest_SNSFailure_MOCK());
        
        test.startTest();
        
        Master_Test__c mtTest = new Master_Test__c();
		mtTest.Public_Test_Description__c = 'CLT_SOMETHING_ANOTHER';
		mtTest.Opportunity_Name__c = 'CLT_SOMETHING_ANOTHER';
		insert mtTest;

		Account acctRespondent = UnitTest_Test_Data.buildTestAccount('Respondent Master Account',userInfo.getUserId());
		insert acctRespondent;

		Contact con1 = UnitTest_Test_Data.BuildContact(1, userInfo.getUserId(), acctRespondent.Id, 'Adult-Respondent');
		insert con1;
        
        test.stopTest();
        
    }
    
}