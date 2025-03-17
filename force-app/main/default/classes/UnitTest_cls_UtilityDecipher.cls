/**
*   {Purpose}  �  TODO:  Provide Purpose
*
*	{Code Covered}	- Note the triggers/classes that this test covers
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   YYYYMMDD  	FN LN DCS			Created
*   =============================================================================
*/
@isTest
private class UnitTest_cls_UtilityDecipher {
	
        @isTest static void testController() {
		
		UnitTest_Test_data.commitFPIApexSettings(true);

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

                Test_Respondent__c trTest = new Test_Respondent__c(Master_Test__c=mtTest.Id, Respondent__c=conTest.Id);
                insert trTest;

                test.startTest();

                List<Utility_Decipher.hClsTargetTR> lstTargets = new List<Utility_Decipher.hClsTargetTR>();
		lstTargets.add(new Utility_Decipher.hClsTargetTR(trTest, mtTest));
		Utility_Decipher.downloadIncompleteResults(lstTargets);

		test.stopTest();

	}

	@isTest static void testBatchable() {

		UnitTest_Test_data.commitFPIApexSettings(true);

		//Account acct = UnitTest_Test_Data.buildTestAccount('Respondent Master Account', UserInfo.getUserId());
		//insert acct;

		//FPI_AppSettings__c testAppSetting1 = UnitTest_Test_data.BuildFPI_AppSettings(ID_RespondentAccount', acct.Id);
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

                Session__c ssTest = new Session__c(Name='Test Session',Related_Test__c=mtTest.Id,Session_Start__c=System.Now().addDays(1),Session_End__c=System.Now().addDays(2));
                insert ssTest;

                Test_Respondent__c trTest = new Test_Respondent__c(Master_Test__c=mtTest.Id, Respondent__c=conTest.Id, Respondent_Status__c='Started');
                insert trTest;

                test.startTest();

                UtilityBatch_DecipherSweeper batchSweeper = new UtilityBatch_DecipherSweeper();
        	database.executeBatch(batchSweeper, 20);

        	test.stopTest();

	}

        @isTest static void testSchedulable() {
                test.startTest();
                System.schedule('Hourly Beacon Results Job - TEST', '0 0 * * * ?', new UtilitySched_Maintenance());
                System.schedule('Daily Data Maintenance Job - TEST', '0 0 2 * * ?', new UtilitySched_MaintData());
                test.stopTest();

        }
	
}