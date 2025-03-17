@isTest
private class UnitTest_PollTriggers {

    //Tests the 3 triggers against the Poll objects - Poll Header, Poll Answer, Poll Respondent

    static testMethod void testTriggers() {
        User testUser = UnitTest_Test_data.buildTestUser(1, 'System Administrator');
        insert(testUser);
        Account act = UnitTest_Test_data.buildTestAccount('Eurofins Client', testUser.Id);
        Contact cnt = UnitTest_Test_data.BuildContact(1, testUser.Id, act.Id, 'Adult-Respondent');
        
        Poll_Header__c ph = new Poll_Header__c();
        ph.Description__c = 'Test';
        ph.End_Date__c = Date.today().addDays(5);
        ph.Start_Date__c = Date.today();
        ph.Title__c = 'Test Poll';
        insert ph;
        
        Poll_Answer__c pa = new Poll_Answer__c();
        pa.Answer_Text__c = 'Test Answer 1';
        pa.Sort_Order__c = 1;
        pa.Poll_Header__c = ph.Id;
        insert pa;
        
        Poll_Respondent__c pr = new Poll_Respondent__c();
        pr.Poll_Header__c = ph.Id;
        pr.Respondent__c = cnt.Id;
        pr.Selected_Answer__c = pa.Id;
        insert pr;
        
    }

}