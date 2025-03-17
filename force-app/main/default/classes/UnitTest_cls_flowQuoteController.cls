/**
*   {Purpose}  �  Test class for flowQuoteController class
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
*   20140508    Eric Gronholz DCS       Created
*   =============================================================================
*/
@isTest
private class UnitTest_cls_flowQuoteController {
    
    @isTest static void constructorTest() {
        /** NO LONGER NEEDED
        User testuser = UnitTest_Test_data.buildTestUser(1, 'System Administrator');
        insert testuser;

        UnitTest_Test_Data.commitFPIApexSettings(true);
        
        Account testAccount = UnitTest_Test_data.buildTestAccount('Eurofins Client', testUser.Id);
        insert testAccount;
        
        //Account testAccountR = UnitTest_Test_data.buildTestAccount('Respondent Master Account', testUser.Id);
        //nsert testAccountR;
        
        //FPI_AppSettings__c testAppSetting1 = UnitTest_Test_data.BuildFPI_AppSettings(testAccountR.Id, 'ID_RespondentAccount');
        //insert testAppSetting1;
        
        //FPI_AppSettings__c testAppSetting2 = UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactBusiness', 'Eurofins Client Contact', 'Contact');
        //insert testAppSetting2;
        
        //FPI_AppSettings__c testAppSetting3 = UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactRespondentAdult', 'Adult-Respondent', 'Contact');
        //insert testAppSetting3;
        
        Contact testContact = UnitTest_Test_data.BuildContact(1, testUser.Id, testaccount.Id, 'Eurofins Client Contact');
        insert testContact;
        
        Opportunity testOpportunity = UnitTest_Test_data.BuildOpportunity(testAccount.Id, 'Consumer Research Opportunity', 'Initiate/Open');
        insert testOpportunity;
        
        Quote testQuote = UnitTest_Test_data.BuildQuote(testOpportunity.Id, 'Test123');
            testQuote.Test_Admin__c = 1000;
            testQuote.Pass_Thru__c = 1000;
            testQuote.Discount__c = 50;
        insert testQuote;
        
        Quote testQuote2 = UnitTest_Test_data.BuildQuote(testOpportunity.Id, 'Test123');
            testQuote.Test_Admin__c = 1000;
            testQuote.Pass_Thru__c = 1000;
            testQuote.Discount__c = 50;
        insert testQuote2;


        test.startTest();        
        
        ApexPages.StandardController controller = new ApexPages.StandardController(testQuote2); 
        PageReference pageRef = Page.QuoteClone;
        pageRef.getParameters().put('id', String.valueOf(testQuote2.Id));
        Test.setCurrentPage(pageRef);

        flowQuoteController fqc = new flowQuoteController(controller);
        PageReference prTest1 = fqc.prFinishLocation;
        fqc.prFinishLocation = prTest1;
        fqc.strOutputVariable = 'a';
        String sTest1 = fqc.strOutputVariable;
        test.stopTest();       
        */
    }
    
}