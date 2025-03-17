/**
*   {Purpose}  �  Provides coverage for the overall Batch/Scheduled TRQ cleanup process
*
*	{Code Covered}	- UtilityBatch_CleanTRQ.cls
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20141105  	Andy Boettcher DCS		Created
*   =============================================================================
*/
@isTest
private class UnitTest_cls_UtilityBatchTRQ {
	
	@isTest static void testController() {
		
        UnitTest_Test_data.commitFPIApexSettings(true);
        UtilityMethods.bolPreventTRQSQS = true;
        UtilityMethods.bolPreventTRSQS = true;

        //Account acct = UnitTest_Test_Data.buildTestAccount('Respondent Master Account', UserInfo.getUserId());
        //insert acct;

        //FPI_AppSettings__c testAppSetting1 = UnitTest_Test_data.BuildFPI_AppSettings('ID_RespondentAccount', acct.Id);
        //insert testAppSetting1;
        
        //FPI_AppSettings__c testAppSetting3 = UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactRespondentAdult', 'Adult-Respondent', 'Contact');
        //FPI_AppSettings__c testAppSetting4 = UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactRespondentChild', 'Child-Respondent', 'Contact');
        //insert testAppSetting3;
        //insert testAppSetting4;

        Id rtId = UtilityMethods.RECORDTYPE_ID('Contact', 'Adult-Respondent');
        Contact conTest = new Contact(Lastname='Lastname',FirstName='firstname',email='me@you.com',birthdate=System.Today().addYears(-40),RecordTypeId=rtId);
        insert conTest;

        Master_Test__c mtTest = new Master_Test__c(Screener_Link__c='http://v2.decipherinc.com/survey/selfserve/testdata/testdata');
        insert mtTest;

        Quota__c mtQuota = new Quota__c(Related_Test__c=mtTest.Id,IsTrackingOnly__c=true);
        mtQuota.Beacon_Condition__c = 'conditionsTestMethod';
        insert mtQuota;

        Session__c seTest1 = new Session__c(Related_Test__c=mtTest.Id);
        seTest1.Name = 'Test Session 1';
        seTest1.Session_Start__c = System.Now();
        seTest1.Session_End__c = System.Now().addHours(1);
        insert seTest1;

        Session_Quota__c seQuota = new Session_Quota__c(Related_Session__c=seTest1.Id,Master_Quota__c=mtQuota.Id);
        insert seQuota;

        Test_Respondent__c trTestDelete = new Test_Respondent__c(Master_Test__c=mtTest.Id, Respondent__c=conTest.Id);
        insert trTestDelete;

        Test_Respondent__c trTestSave = new Test_Respondent__c(Master_Test__c=mtTest.Id, Respondent__c=conTest.Id);
        insert trTestSave;

        test.startTest();

        Test_Respondent_Quota__c trqDelete = new Test_Respondent_Quota__c(Test_Respondent__c=trTestDelete.Id, Session_Quota__c=seQuota.Id);
        insert trqDelete;
        Test_Respondent_Quota__c trqSave = new Test_Respondent_Quota__c(Test_Respondent__c=trTestSave.Id, Session_Quota__c=seQuota.Id);
        insert trqSave;

        UtilityBatch_CleanTRQ trqCustodian = new UtilityBatch_CleanTRQ();
        trqCustodian.strQuery = 'SELECT Id FROM Test_Respondent_Quota__c WHERE Test_Respondent__c = \'' + trTestDelete.Id + '\'';
        database.executeBatch(trqCustodian, 9999);

        test.stopTest();

        List<Test_Respondent_Quota__c> lstTRQDelete = [SELECT Id FROM Test_Respondent_Quota__c WHERE Test_Respondent__c = :trTestDelete.Id];
        List<Test_Respondent_Quota__c> lstTRQSave = [SELECT Id FROM Test_Respondent_Quota__c WHERE Test_Respondent__c = :trTestSave.Id];

        System.Assert(lstTRQDelete.size() == 0, 'Batch did not delete!');
        System.Assert(lstTRQSave.size() == 1, 'Batch deleted the wrong one!');

	}
	
}