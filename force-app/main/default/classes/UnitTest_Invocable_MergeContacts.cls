@isTest
private class UnitTest_Invocable_MergeContacts {
	
	@isTest static void unitTest1() {

        User testuser = UnitTest_Test_data.buildTestUser(1, 'System Administrator');
        insert testuser;

        UnitTest_Test_Data.commitFPIApexSettings();
        
        Account testAccount = UnitTest_Test_data.buildTestAccount('Eurofins Client', testUser.Id);
        insert testAccount;
        
        Contact testContact = UnitTest_Test_data.BuildContact(1, testUser.Id, testaccount.Id, 'Eurofins Client Contact');
        insert testContact;

        Contact testContact2 = UnitTest_Test_data.BuildContact(1, testUser.Id, testaccount.Id, 'Eurofins Client Contact');
        insert testContact2;
        
        List<Invocable_MergeContacts.ContactId> contactIds = new List<Invocable_MergeContacts.ContactId>();
        Invocable_MergeContacts.ContactId myVars = new Invocable_MergeContacts.ContactId();
        myVars.masterContact = testContact.Id;
        myVars.mergeContact2 = testContact2.Id;
        myVars.mergeContact3 = null;
        contactIds.add(myVars);

        List<String> resultList = Invocable_MergeContacts.mergeContacts(contactIds);
        System.assertEquals(resultList[0], testContact.Id);
    }
}