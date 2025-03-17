@isTest
private class UnitTest_PopulationDefinition_Trigger {

    //Tests the 3 triggers against the Poll objects - Poll Header, Poll Answer, Poll Respondent

    static testMethod void testTriggers() {
        User testUser = UnitTest_Test_data.buildTestUser(1, 'System Administrator');
        insert(testUser);
        //Account act = UnitTest_Test_data.buildTestAccount('Eurofins Client', testUser.Id);
        //Contact cnt = UnitTest_Test_data.BuildContact(1, testUser.Id, act.Id, 'Adult-Respondent');
        
        Master_Test__c testMasterTest = UnitTest_Test_data.BuildMasterTest();
        insert testMasterTest;

        Population_Definition__c testPD = new Population_Definition__c();
        testPD.Master_Test__c = testMasterTest.Id;
        insert testPD;
        
    }

}