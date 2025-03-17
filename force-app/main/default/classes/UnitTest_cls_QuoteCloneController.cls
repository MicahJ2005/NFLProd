/**
*   {Purpose}  �  Test class for QuoteCloneController class
*                 
*   {Function}  � DESCRIBE PUBLIC FUNCTIONS
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name                    Description
*   20140512    Eric Gronholz DCS       Created
*   =============================================================================
*/
@isTest
private class UnitTest_cls_QuoteCloneController {
    
    @isTest static void myUnitTest() {
        /** NO LONGER NEEDED
        User testuser = UnitTest_Test_data.buildTestUser(1, 'System Administrator');
        insert testuser;

        UnitTest_Test_Data.commitFPIApexSettings();
        
        Account testAccount = UnitTest_Test_data.buildTestAccount('Eurofins Client', testUser.Id);
        insert testAccount;
        
        Account testAccountR = UnitTest_Test_data.buildTestAccount('Respondent Master Account', testUser.Id);
        insert testAccountR;
        
        FPI_AppSettings__c testAppSetting1 = UnitTest_Test_data.BuildFPI_AppSettings(testAccountR.Id, 'ID_RespondentAccount');
        insert testAppSetting1;
        
        //FPI_AppSettings__c testAppSetting2 = UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactBusiness', 'Eurofins Client Contact', 'Contact');
        //insert testAppSetting2;
        
        //FPI_AppSettings__c testAppSetting3 = UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactRespondentAdult', 'Adult-Respondent', 'Contact');
        //insert testAppSetting3;
        
        Contact testContact = UnitTest_Test_data.BuildContact(1, testUser.Id, testaccount.Id, 'Eurofins Client Contact');
        insert testContact;
        
        Opportunity testOpportunity = UnitTest_Test_data.BuildOpportunity(testAccount.Id, 'Consumer Research Opportunity', 'Initiate/Open');
        insert testOpportunity;
        
        Quote testQuote1 = UnitTest_Test_data.BuildQuote(testOpportunity.Id, 'Test123');
            testQuote1.Test_Admin__c = 1000;
            testQuote1.Pass_Thru__c = 1000;
            testQuote1.Discount__c = 50;
        insert testQuote1;

        test.startTest();
        ApexPages.StandardController controller = new ApexPages.StandardController(testQuote1); 
        PageReference pageRef = Page.QuoteClone;
        pageRef.getParameters().put('id', String.valueOf(testQuote1.Id));
        Test.setCurrentPage(pageRef);
        
        QuoteCloneController qcc = new QuoteCloneController(controller);
        qcc.cloneRecord();
        test.stopTest();
        */
    }
    
}