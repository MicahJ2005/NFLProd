/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name / Description
*   07.30.2021  Sophia Murphy (Demand Chain)
*               Initial creation
*   =============================================================================
*/
@isTest
private class UnitTest_cls_PushNotifications_Handler {
    
    @isTest static void unitTest1() {

        UnitTest_Test_Data.commitFPIApexSettings();

        User testuser = UnitTest_Test_data.buildTestUser(1, 'System Administrator');
        insert testuser;

        Account testAccount = UnitTest_Test_data.buildTestAccount('Respondent Master Account', testUser.Id);
        insert(testAccount);
        
        Contact testContactAdult = UnitTest_Test_data.BuildContact(1, testUser.Id, testAccount.Id, 'Adult-Respondent');
        testContactAdult.Email = 'testadult@tester.com';
        insert testContactAdult;

        testContactAdult.Push_Notification_Device_Id__c = 'testDeviceId';
        testContactAdult.Push_Notification_User_Id__c = 'testUserId';
        update testContactAdult;

        Test_Respondent__c trTest = new Test_Respondent__c();
		trTest.Respondent__c = testContactAdult.Id;
		insert trTest;

        testContactAdult.Push_Notification_Merge_Successful__c = true;
        update testContactAdult;

        Push_Notification__c pn = new Push_Notification__c();
        pn.Use_Case__c = 'Scheduled Email Adult';
        pn.Contact__c = testContactAdult.Id;
        pn.Test_Respondent__c = trTest.Id;
        insert pn;

    }
}