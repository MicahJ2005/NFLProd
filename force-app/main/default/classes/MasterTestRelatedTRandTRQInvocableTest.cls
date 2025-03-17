/**
 * @description       : Test class for MasterTestRelatedTRandTRQInvocable
 * @author            : James Loghry (Demand Chain)
 * @group             : Demand Chain
 * @last modified on  : 05-07-2021
 * @last modified by  : James Loghry (Demand Chain)
 * Modifications Log
 * Ver   Date         Author                        Modification
 * 1.0   05-06-2021   James Loghry (Demand Chain)   Initial Version
**/
@isTest
private class MasterTestRelatedTRandTRQInvocableTest {

    //Borrowed from another Master Test related unit test :)
    @testSetup static void testDataSetup() {
        UnitTest_Test_Data.commitFPIApexSettings(true);
        /**List<FPI_AppSettings__c> lstInsertAppSettings = new List<FPI_AppSettings__c>();
        lstInsertAppSettings.add(new FPI_AppSettings__c(Name='CurrentCheckNumber',Value__c='1000'));
        lstInsertAppSettings.add(new FPI_AppSettings__c(Name='Valtira_PositivePay_Endpoint',Value__c='https://pdf-api.valtira.com/fill-acro-form/bulk'));
        lstInsertAppSettings.add(new FPI_AppSettings__c(Name='Valtira_Endpoint',Value__c='https://pdf-api.valtira.com/fill-acro-form/bulk'));
        lstInsertAppSettings.add(new FPI_AppSettings__c(Name='Valtira_MICRUrl',Value__c='https://s3.us-east-2.amazonaws.com/fpi-chex/IDAutomationMICR.ttf'));
        lstInsertAppSettings.add(new FPI_AppSettings__c(Name='Valtira_S3Bucket',Value__c='fpi-chex'));
        lstInsertAppSettings.add(new FPI_AppSettings__c(Name='Valtira_S3Region',Value__c='US_EAST_2'));
        lstInsertAppSettings.add(new FPI_AppSettings__c(Name='Valtira_Template',Value__c='CheckTemplatev1-7.pdf'));
        lstInsertAppSettings.add(new FPI_AppSettings__c(Name='Valtira_CheckSignature',Value__c='https://s3.us-east-2.amazonaws.com/fpi-chex/CovanceSig.png'));
        lstInsertAppSettings.add(new FPI_AppSettings__c(Name='Valtira_CheckThankYou',Value__c='https://s3.us-east-2.amazonaws.com/fpi-chex/thank-you-cursive.jpg'));
        lstInsertAppSettings.add(new FPI_AppSettings__c(Name='Valtira_APIKey',Value__c='SRm9c5uVVA630JFh4jXjzan1YEwA7A4P2TIqkSBS'));
        lstInsertAppSettings.add(new FPI_AppSettings__c(Name='Valtira_PositivePay_APIKey',Value__c='https://pdf-api.valtira.com/fill-acro-form/bulk'));
        insert lstInsertAppSettings;
        insert new FPI_APEXSettings__c(Name='TransmitCheckDataToWFPositivePay', IsActive__c=true);
        */
        // Create Contact and Household
        Contact conTest = UnitTest_Test_data.createRespondent();
        Household__c hseNew = new Household__c(
            MailingStreet__c = '1234 MyStreet',
            MailingStreet2__c = 'Executive Suite',
            MailingCity__c = 'Plymouth',
            MailingState__c = 'MN',
            MailingPostalCode__c = '55555'
        ); 
        insert hseNew;
        Household_Contact__c hcNew = new Household_Contact__c(Household__c=hseNew.Id, Contact__c=conTest.Id);
        insert hcNew;
        Master_Test__c mtTest = new Master_Test__c();
        mtTest.Public_Test_Description__c = 'Test Master Test';
        insert mtTest;
        Quota__c mtQuota = new Quota__c(Related_Test__c=mtTest.Id);
        mtQuota.IsOpen__c = true;
        mtQuota.Beacon_Condition__c = 'conditionsTest';
        insert mtQuota;
        Session__c seTest = new Session__c(Related_Test__c=mtTest.Id);
        seTest.Name = 'Test Session';
        seTest.Session_Start__c = System.Now();
        seTest.Session_End__c = System.Now().addHours(1);
        seTest.Check_Amount__c = 69.00;
        seTest.Recruits_Per_Session__c = 50;
        insert seTest;
        Session_Quota__c sqTest = new Session_Quota__c();
        sqTest.Master_Quota__c = mtQuota.Id;
        sqTest.Related_Session__c = seTest.Id;
        sqTest.IsOpen__c = true;
        insert sqTest;
        Test_Respondent__c trTest = new Test_Respondent__c();
        trTest.Master_Test__c = mtTest.Id;
        trTest.Respondent__c = conTest.Id;
        trTest.Check_Amount__c = 69.00;
        insert trTest;
        Test_Respondent_Quota__c trqTest = new Test_Respondent_Quota__c();
        trqTest.Test_Respondent__c = trTest.Id;
        trqTest.Session_Quota__c = sqTest.Id;
        trqTest.IsQualified__c = true;
        trqTest.IsScheduled__c = true;
        insert trqTest;
    }
    
    static testmethod void testInvocableMethod(){
        Master_Test__c mt = [Select Id From Master_Test__c];
        Test.startTest();
        MasterTestRelatedTRandTRQInvocable.updateRelatedRecords(new List<Id>{ mt.Id });
        Test.stopTest();
    }
}