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
private class UnitTest_Opportunity_Trigger {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        User testuser = UnitTest_Test_data.buildTestUser(1, 'System Administrator');
        insert testuser;

        //Setup the custom settings
        UnitTest_Test_Data.commitFPIApexSettings(true);

        Account testAccount = UnitTest_Test_data.buildTestAccount('Eurofins Client', testUser.Id);
        insert testAccount;
        
        //Account testAccountR = UnitTest_Test_data.buildTestAccount('Respondent Master Account', testUser.Id);
        //insert testAccountR;
        
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
/** 
        Project_Detail__c testPD = UnitTest_Test_data.BuildProjectDetail(Null);
        insert testPD;
        
        Project_Detail__c testPD2 = UnitTest_Test_data.BuildProjectDetail(testPD.Id);
        insert testPD2;

        PD_Junction__c testPDJ = UnitTest_Test_data.BuildPDJunction(testPD2.Id, testQuote.Id);
        insert testPDJ;
        
        PD_Junction__c testPDJ2 = UnitTest_Test_data.BuildPDJunction(testPD2.Id, testQuote2.Id);
        insert testPDJ2;
*/
        // ATC__Hlist__c avataList = new ATC__Hlist__c();
        // avataList.Opportunity__c = testOpportunity.Id;
        //insert avataList;

        // system.runAs(testuser)
        // {
        //     //getting mixed dml errors, doing this insert as a different user
        //     insert avataList;
        // }


        test.startTest();
            testQuote.Status = 'Signature';
            update testQuote;
            testOpportunity.StageName = 'Approved';
            update testOpportunity;
            for(Opportunity ocheck: [SELECT Amount, StageName FROM Opportunity WHERE ID = :testopportunity.Id]){
//                  System.assertEquals(1500, ocheck.Amount);
                    //System.assertEquals('Closed Won', ocheck.StageName);            
                }
            for(PD_Junction__c PDJcheck: [SELECT RelatedId__c FROM PD_Junction__c WHERE RelatedId__c = :testopportunity.Id]){
                    System.assertEquals(testopportunity.Id, PDJcheck.RelatedId__c);
                }
            for(Quote QuoteCheck1: [SELECT Status FROM Quote WHERE ID = :testQuote2.Id]){
                    //System.assertEquals('Rejected', QuoteCheck1.Status);
                }   

            testOpportunity.StageName = 'Invoiced';
            update testOpportunity;
            
        test.stopTest();
        
    }
}