/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class UnitTest_cls_QuoteClone_Flow {

    static testMethod void myUnitTest() {
        /** NO LONGER NEEDED
        // TO DO: implement unit test
        User testuser = UnitTest_Test_data.buildTestUser(1, 'System Administrator');
        insert testuser;

        UnitTest_Test_Data.commitFPIApexSettings();
        
        Account testAccount = UnitTest_Test_data.buildTestAccount('Eurofins Client', testUser.Id);
        insert testAccount;
        
        Account testAccountR = UnitTest_Test_data.buildTestAccount('Respondent Master Account', testUser.Id);
        insert testAccountR;
        
        FPI_AppSettings__c testAppSetting1 = UnitTest_Test_data.BuildFPI_AppSettings('ID_RespondentAccount', testAccountR.Id);
        insert testAppSetting1;
        
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
 
        test.startTest();
        	QuoteClone_Flow plugin = new QuoteClone_Flow();
        	Map<String,Object> inputParams = new Map<String,Object>();

        	ID QuoteID = testQuote.Id;
        	InputParams.put('QuoteID', QuoteID);
        	ID OpportunityID = testOpportunity.Id;
        	InputParams.put('OpportunityID', OpportunityID);

        	Process.PluginRequest request = new Process.PluginRequest(inputParams);           
        
        	Process.PluginResult result = plugin.invoke(request);
        
        	Map<String, Object> returnMap = result.outputParameters;
        	
        	List<Quote> lstQuotes = [SELECT Id FROM Quote];
        	System.AssertEquals(lstQuotes.size(), 2);
        
        test.stopTest();
        
        */
    }
}