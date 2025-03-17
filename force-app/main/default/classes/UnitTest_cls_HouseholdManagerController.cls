/**
*   {Purpose}  �  Unit Test for HouseholdManagerController
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name                    Description
*   20140507    Andy Boettcher DCS      Created
*   20140522    Andy Boettcher DCS      Refactored for new functionality
*   =============================================================================
*/
@isTest
private class UnitTest_cls_HouseholdManagerController {
    
    @isTest static void testHouseholdController() {
        
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
        Contact conMinor = UnitTest_Test_data.BuildContact(1, testUser.Id, testAccount.Id, 'Child-Respondent');
        conMinor.BirthDate = System.Today().addYears(-15);
        lstContacts.add(conMinor);
        insert lstContacts;
        
        ///////////////////////
        // Start Test
        ///////////////////////
        test.startTest();

        System.Debug('1 ********************** ' + Limits.getQueries());

        // Create Household
        Household__c hseMain = new Household__c();
        hseMain.MailingStreet__c = '123 MyStreet Road';
        hseMain.MailingState__c = 'MN';
        hseMain.Head_of_Household__c = [SELECT Id FROM Contact WHERE RecordType.Name = 'Adult-Respondent' LIMIT 1].Id;
        insert hseMain;

        System.Debug('1A ********************** ' + Limits.getQueries());

        // Invoke Controller
        HouseholdManagerController clsHouse = new HouseholdManagerController(new ApexPages.StandardController(hseMain));

        // Associate all Contacts to Household
        List<Household_Contact__c> lstInsertMembers = new List<Household_Contact__c>();
        for(Contact con : [SELECT Id FROM Contact WHERE RecordType.Name = 'Adult-Respondent' OR RecordType.Name = 'Child-Respondent' LIMIT 5]) {
            String strAddResult = HouseholdManagerController.addRespondent(hseMain.Id, con.Id);
            System.Debug('1B ********************** ' + Limits.getQueries());
            System.Assert(strAddResult == 'success', 'Household Member was not added properly!');
        }

        System.Debug('2 ********************** ' + Limits.getQueries());

        // Refresh Member List, verify 5 exist
        clsHouse.refreshMemberList();
        System.Assert(clsHouse.lstMembers.size() == 2, 'Too few HH Members are present!');

        // Save full Respondent List
        clsHouse.saveMembers();

        // Remove Respondent
        Household_Contact__c hhcRemove = [SELECT Id FROM Household_Contact__c LIMIT 1];
        clsHouse.strRespondentId = hhcRemove.Id;
        clsHouse.removeRespondent();

        System.Debug('3 ********************** ' + Limits.getQueries());

        // Refresh Member List, verify 4 exist
        clsHouse.refreshMemberList();
        System.Assert(clsHouse.lstMembers.size() == 1, 'Too few HH Members are present!');

        // Add New Respondent
        clsHouse.conNew = UnitTest_Test_data.BuildContact(10, testUser.Id, testAccount.Id, 'Adult-Respondent');
        clsHouse.saveNew();

        System.Debug('4 ********************** ' + Limits.getQueries());

        // Merge Household
        clsHouse.mergeHousehold();

        // Search for Contacts to add to household
        List<Contact> lstSearchEmpty = clsHouse.getLstContacts();
        System.Assert(lstSearchEmpty.size() == 0, 'Empty Contact search failed!');

        System.Debug('5 ********************** ' + Limits.getQueries());

        clsHouse.conSearch.Title = 'Smith10';
        clsHouse.conSearch.Firstname = 'John10';
        List<Contact> lstSearch = clsHouse.getLstContacts();



    }

    
}