/**
*   {Purpose}  �  Unit Test for HouseholdMergeController
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name                    Description
*   20140522    Andy Boettcher DCS      Created
*   =============================================================================
*/
@isTest
private class UnitTest_cls_HouseholdMergeController {
	
	@isTest static void testHouseholdMergeController() {
		
		UnitTest_Test_Data.commitFPIApexSettings();
        
        User testuser = UnitTest_Test_data.buildTestUser(1, 'System Administrator');
        insert testuser;
        
        Account testAccount = UnitTest_Test_data.buildTestAccount('Eurofins Client', testUser.Id);
        insert testAccount;
        
        FPI_AppSettings__c testAppSetting1 = UnitTest_Test_data.BuildFPI_AppSettings('ID_RespondentAccount', Testaccount.Id);
        insert testAppSetting1;
        
        //FPI_AppSettings__c testAppSetting3 = UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactRespondentAdult', 'Adult-Respondent', 'Contact');
        //FPI_AppSettings__c testAppSetting4 = UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactRespondentChild', 'Child-Respondent', 'Contact');
        //insert testAppSetting3;
        //insert testAppSetting4;

        List<Contact> lstContacts = new List<Contact>();
        lstContacts.add(UnitTest_Test_data.BuildContact(1, testUser.Id, testAccount.Id, 'Adult-Respondent'));
        lstContacts.add(UnitTest_Test_data.BuildContact(2, testUser.Id, testAccount.Id, 'Adult-Respondent'));
        lstContacts.add(UnitTest_Test_data.BuildContact(3, testUser.Id, testAccount.Id, 'Adult-Respondent'));
        lstContacts.add(UnitTest_Test_data.BuildContact(4, testUser.Id, testAccount.Id, 'Adult-Respondent'));
        insert lstContacts;

        // Create Households
        Household__c hseSource = new Household__c();
        hseSource.MailingStreet__c = '123 MyStreet Road';
        hseSource.MailingState__c = 'MN';
        insert hseSource;

        Household__c hseTarget = new Household__c();
        hseTarget.MailingStreet__c = '456 YourStreet Road';
        hseTarget.MailingState__c = 'MN';
        insert hseTarget;

        // Add Respondents to Household
        List<Household_Contact__c> lstMembers = new List<Household_Contact__c>();
        for(Contact con : [SELECT Id FROM Contact WHERE Lastname = 'Smith1' OR Lastname = 'Smith2']) {
        	lstMembers.add(new Household_Contact__c(Household__c=hseSource.Id, Contact__c=con.Id));
        }

        for(Contact con : [SELECT Id FROM Contact WHERE Lastname = 'Smith3' OR Lastname = 'Smith4']) {
        	lstMembers.add(new Household_Contact__c(Household__c=hseTarget.Id, Contact__c=con.Id));
        }

        ///////////////////////
        // Start Test
        ///////////////////////
        test.startTest();

        // Invoke Controller
        HouseholdMergeController clsMerge = new HouseholdMergeController(new ApexPages.StandardController(hseSource));
        clsMerge.hhcTargetLookup.Household__c = hseTarget.Id;

        // Perform Searches
        Household__c householdSource = clsMerge.householdSource;
        clsMerge.householdSource = clsMerge.householdSource;
        List<Household_Contact__c> lstSourceMembers = clsMerge.householdSourceMembers;
        clsMerge.householdSourceMembers = clsMerge.householdSourceMembers;
        Household__c householdTarget = clsMerge.householdTarget;
        clsMerge.householdTarget = clsMerge.householdTarget;
        List<Household_Contact__c> lstTargetMembers = clsMerge.householdTargetMembers;
        clsMerge.householdTargetMembers = clsMerge.householdTargetMembers;

        // Perform Merge - Positive
        clsMerge.mergeHouseholds();

	}
	

}