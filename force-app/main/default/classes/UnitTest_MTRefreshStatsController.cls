@isTest 
private class UnitTest_MTRefreshStatsController {

    static testMethod void myUnitTest() {
        //Make a master test - that is in the status of approved...

        Account acctTest = UnitTest_Test_Data.buildTestAccount('Eurofins Client', Userinfo.getUserId()); 
        insert acctTest;
        
		Opportunity oppTest = UnitTest_Test_Data.BuildOpportunity(acctTest.Id,'Consumer Research Opportunity', 'Initiate/Open'); 
        oppTest.Project_Stage__c = 'Approved';
        insert oppTest;
		
		Master_Test__c mtTest = UnitTest_Test_Data.BuildMasterTest();
		mtTest.Opportunity__c = oppTest.Id;
        insert mtTest;

        PageReference testPg = Page.MTRefreshStats;   
        testPg.getParameters().put('Id', mtTest.Id);
        Test.setCurrentPage(testPg);
        ApexPages.StandardController sc = new ApexPages.StandardController(mtTest);
        MTRefreshStatsController controller = new MTRefreshStatsController(sc);
        
        controller.runMe();
        controller.returnToMT();
        
    }

    static testMethod void myUnitTest2() {
        //Make a master test - that is in the status of approved...

        Account acctTest = UnitTest_Test_Data.buildTestAccount('Eurofins Client', Userinfo.getUserId()); 
        insert acctTest;
        
		Opportunity oppTest = UnitTest_Test_Data.BuildOpportunity(acctTest.Id,'Consumer Research Opportunity', 'Initiate/Open'); 
        oppTest.Project_Stage__c = 'Approved';
        insert oppTest;
		
		Master_Test__c mtTest = UnitTest_Test_Data.BuildMasterTest();
		mtTest.Opportunity__c = oppTest.Id;
        insert mtTest;

        Test.startTest();
            //trying to get the execute method covered.
            List<Master_Test__c> mtList =  new List<Master_Test__c>();
            mtList.add(mtTest);
           
            MTRefreshStatsBatch batchClass = new MTRefreshStatsBatch();
            Id batchJobId = Database.executeBatch(batchClass);
            batchClass.execute(null, mtList);
            System.abortJob(batchJobId);

        Test.stopTest();
    }

    static testMethod void myUnitTest3() {
        //Make a master test - that is in the status of approved...

        Account acctTest = UnitTest_Test_Data.buildTestAccount('Eurofins Client', Userinfo.getUserId()); 
        insert acctTest;
        
		Opportunity oppTest = UnitTest_Test_Data.BuildOpportunity(acctTest.Id,'Consumer Research Opportunity', 'Initiate/Open'); 
        oppTest.Project_Stage__c = 'Approved';
        insert oppTest;
		
		Master_Test__c mtTest = UnitTest_Test_Data.BuildMasterTest();
		mtTest.Opportunity__c = oppTest.Id;
        insert mtTest;

        Test.startTest();
            MTRefreshStatsBatch batchClass = new MTRefreshStatsBatch(); 
            batchClass.query = 'SELECT Id FROM Master_Test__c WHERE Master_Test_Status_1__c = \'Approved\' ';
            Database.ExecuteBatch(batchClass, 1);

            System.schedule('my batch job', '0 0 0 1 1 ?', new MTRefreshStatsBatch() );
        Test.stopTest();
    }
}