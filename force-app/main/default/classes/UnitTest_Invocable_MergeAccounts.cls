@isTest
private class UnitTest_Invocable_MergeAccounts {
  
  @isTest static void unitTest1() {

        User testuser = UnitTest_Test_data.buildTestUser(1, 'System Administrator');
        insert testuser;

        UnitTest_Test_Data.commitFPIApexSettings();
        
        Account testAccount = UnitTest_Test_data.buildTestAccount('Eurofins Client', testUser.Id);
        insert testAccount;
        
        Account testAccount2 = UnitTest_Test_data.BuildTestAccount('Eurofins Client', testUser.Id);
        insert testAccount2;

        Account testAccount3 = UnitTest_Test_data.BuildTestAccount('Eurofins Client', testUser.Id);
        insert testAccount3;
        
        List<Invocable_MergeAccounts.AccountId> accountIds = new List<Invocable_MergeAccounts.AccountId>();
        Invocable_MergeAccounts.AccountId myVars = new Invocable_MergeAccounts.AccountId();
        myVars.masterAccount = testAccount.Id;
        myVars.mergeAccount2 = testAccount2.Id;
        myVars.mergeAccount3 = null;
        accountIds.add(myVars);

        List<String> resultList = Invocable_MergeAccounts.mergeAccounts(accountIds);
        System.assertEquals(resultList[0], testAccount.Id);
    }
}