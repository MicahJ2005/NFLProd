/**
 * @description       : CTest Class for MasterQuotaDatatableControllerTest 
 * @coverage          : %100
 *
 * @author            : Matthew J Lennington
 * @group             : Demand Chain
 * @last modified on  : 2024-02-19
 * @last modified by  : Matthew J Lennington
 * @change            :
 *
*/
@isTest
public with sharing class MasterQuotaDatatableControllerTest {
    @testSetup
    private static void testSetup() {
        //Borrowed from another Master Test related unit test :)
        UnitTest_Test_Data.commitFPIApexSettings();
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
    }
    

    @isTest
    public static void getMasterQuotaTest() {
        Id testId = [SELECT ID FROM Master_Test__c LIMIT 1].Id;
        Test.startTest();
        List<Quota__c> quotas = MasterQuotaDatatableController.getMasterQuota(testId);
        Test.stopTest();

        assert.areEqual(1, quotas.size(), 'Should have 1 quota returned');
    }


    @isTest
    public static void save() {
        Quota__c mtQuota = [SELECT ID, IsOpen__c FROM Quota__c Limit 1];
        mtQuota.IsOpen__c = false;
        Test.startTest();
        MasterQuotaDatatableController.save(new List<Quota__c>{mtQuota});
        Test.stopTest();
        Quota__c resultQuota = [SELECT ID, IsOpen__c FROM Quota__c Limit 1];
        
        assert.areEqual(mtQuota.Id, resultQuota.Id, 'Not Comparing the same quota');
        assert.areEqual(false, resultQuota.IsOpen__c, 'IsOpen__c field should be false');
    }
}