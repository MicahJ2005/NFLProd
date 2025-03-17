/**
*   {Purpose}  �  Unit Test for CheckGenerator_TRListController
/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name                    
*   20201209    Sophia Murphy (Demand Chain)
*               Initial Creation
*   =============================================================================
*/
@isTest
private class UnitTest_CheckGenerator_TRListController {
    
    @isTest static void unitTest1() {

        UnitTest_Test_Data.commitFPIApexSettings(true);

		Master_Test__c mtTest = new Master_Test__c();
		mtTest.Public_Test_Description__c = 'Test Master Test';
		insert mtTest;

		Quota__c mtQuota = new Quota__c(Related_Test__c=mtTest.Id);
		mtQuota.Beacon_Condition__c = 'conditionsTestMethod';
		insert mtQuota;

		Session__c seTest = new Session__c(Related_Test__c=mtTest.Id);
		seTest.Name = 'Test Session';
		seTest.Session_Start__c = System.Now();
		seTest.Session_End__c = System.Now().addHours(1);
		insert seTest;

		Session_Quota__c sqTest = new Session_Quota__c();
		sqTest.Master_Quota__c = mtQuota.Id;
		sqTest.Related_Session__c = seTest.Id;
		insert sqTest;

        Contact conTest = UnitTest_Test_data.createRespondent();
        Contact conTest2 = UnitTest_Test_data.createRespondent();

        FPI_AppSettings__c csAppSettings = FPI_AppSettings__c.getInstance('CurrentCheckNumber');
		Integer intNextCheckNumber = Integer.valueOf(csAppSettings.Value__c);

		Test_Respondent__c trTest = new Test_Respondent__c();
		trTest.Master_Test__c = mtTest.Id;
        trTest.Respondent__c = conTest.Id;
        trTest.Check_Amount__c = 20.00;
        trTest.Check_Number__c = String.valueOf(intNextCheckNumber);
        trTest.Check_Printed_Date__c = Date.newInstance(2022,12,12);
        //trTest.Check_Number__c = '000000';
		//insert trTest;

        Test_Respondent__c trTest2 = new Test_Respondent__c();
		trTest2.Master_Test__c = mtTest.Id;
        trTest2.Respondent__c = conTest2.Id;
        trTest2.Check_Amount__c = 20.00;
        trTest2.Check_Number__c = String.valueOf(intNextCheckNumber+1);
        trTest2.Check_Printed_Date__c = Date.newInstance(2022,12,12);
        //trTest2.Check_Number__c = '000001';
        //insert trTest2;

        List<Test_Respondent__c> trList = new List<Test_Respondent__c>();
        trList.add(trTest);
        trList.add(trTest2);
        insert trList;

        Test.startTest();
        Test.setCurrentPage(Page.CheckGenerator_TRList);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(trList);
        stdSetController.setSelected(trList);
        CheckGenerator_TRListController ext = new CheckGenerator_TRListController(stdSetController);
        ext.runValtiraChecks();
        ext.cancel();
        Test.stopTest();

    }
}