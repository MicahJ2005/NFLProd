@isTest
private class UnitTest_Invocable_FindCQUser {
	
	@isTest static void unitTest1() {

        //First - update any users that already have this data filled in
        List<User> updUsers = new List<User>();
        for(User u : [SELECT Id, CQ_Start_Time__c, CQ_End_Time__c FROM User WHERE CQ_Start_Time__c != null]) {
            u.CQ_Start_Time__c = null;
            u.CQ_End_Time__c = null;
            updUsers.add(u);
        }
        update updUsers;

        List<User> usrList = new List<User>();
        User usr1 = UnitTest_Test_Data.buildTestUser(1, 'System Administrator');
        usr1.CQ_Start_Time__c = '7:00 AM';
        usr1.CQ_End_Time__c = '10:00 PM';
        usr1.CQ_Assignment_Bypass__c = false;
        usr1.CQ_Last_Assigned__c = null;
        usrList.add(usr1);

        User usr2 = UnitTest_Test_Data.buildTestUser(2, 'System Administrator');
        usr2.CQ_Start_Time__c = '7:00 AM';
        usr2.CQ_End_Time__c = '10:00 PM';
        usr2.CQ_Assignment_Bypass__c = true; //bypass
        usr2.CQ_Last_Assigned__c = null;
        usrList.add(usr2);

        insert usrList;
        List<String> resultList = Invocable_FindCQUser.findUser();
        System.assertEquals(resultList[0], usr1.Id);

        //This will fail - it's the FLOW that sets the Last Assigned
        //usr1 = [SELECT Id, CQ_Last_Assigned__c FROM User WHERE Id = :usr1.Id];
        //System.assertNotEquals(usr1.CQ_Last_Assigned__c, null);

        usr2.CQ_Assignment_Bypass__c = false;
        update usr2;

        resultList = Invocable_FindCQUser.findUser();
        System.assertEquals(resultList[0], usr2.Id);

    }
}