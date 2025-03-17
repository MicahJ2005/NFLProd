@isTest
private class UnitTest_Invocable_RespondentSetPassword {
	
	@isTest static void testController() {
        List<FPI_AppSettings__c> lstAppSettings = new List<FPI_AppSettings__c>();
        lstAppSettings.add(UnitTest_Test_data.BuildFPI_AppSettings('Valtira_SetPassword_APIKey', 'thisisatestkey'));
        lstAppSettings.add(UnitTest_Test_Data.BuildFPI_AppSettings('Valtira_SetPassword_EndPt', 'notarealurl.com'));
        insert lstAppSettings;

        String testEmail = 'something@something.com';
        String testPW = 'helloworld';
        List<String> passInValue = new List<String>();
        passInValue.add(testEmail + ';' + testPW);

        //Invocable_RespondentSetPassword cntrlr = new Invocable_RespondentSetPassword();
        Invocable_RespondentSetPassword.runSetPassword(passInValue);

    }
}