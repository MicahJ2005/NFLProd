/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class UnitTest_HseContact_Triggers
{
    static testMethod void testTriggers()
    {
        User testuser = UnitTest_Test_data.buildTestUser(1, 'System Administrator');
        insert(testuser);

        UnitTest_Test_Data.commitFPIApexSettings();
        
        Account testAccount = UnitTest_Test_data.buildTestAccount('Respondent Master Account', testUser.Id);
        insert(testAccount);
        
        Contact testContact01 = UnitTest_Test_data.BuildContact(1, testUser.Id, testaccount.Id, 'Adult-Respondent');
        testContact01.Email = 'test01@tester.com';
        insert(testContact01);
        
        Contact testContact02 = UnitTest_Test_data.BuildContact(1, testUser.Id, testaccount.Id, 'Adult-Respondent');
        testContact02.Email = 'test02@tester.com';
        insert(testContact02);
        
        Household__c testHousehold01 = new Household__c();
        testHousehold01.Head_of_Household__c = testContact01.Id;
        insert(testHousehold01);

        Household__c testHousehold02 = new Household__c();
        testHousehold02.Head_of_Household__c = testContact02.Id;
        insert(testHousehold02);

        Test.startTest();

	        Household_Contact__c testHouseholdContact = new Household_Contact__c();
	        testHouseholdContact.Contact__c = testContact01.Id;
	        testHouseholdContact.Household__c = testHousehold01.Id;
	        insert(testHouseholdContact);

	        Contact insertedContact = [SELECT Household_Contact_Email__c FROM Contact WHERE Id = :testContact01.Id];
	        System.assert(insertedContact.Household_Contact_Email__c == 'test01@tester.com', 'Household Contact Email NOT Inserted');

	        testHouseholdContact.Household__c = testHousehold02.Id;
	        update(testHouseholdContact);

	        Contact updatedContact = [SELECT Household_Contact_Email__c FROM Contact WHERE Id = :testContact01.Id];
	        System.assert(updatedContact.Household_Contact_Email__c == 'test02@tester.com', 'Household Contact Email NOT Updated');

	        delete(testHouseholdContact);

	        Contact deletedContact = [SELECT Household_Contact_Email__c FROM Contact WHERE Id = :testContact01.Id];
	        System.assert(deletedContact.Household_Contact_Email__c == null, 'Household Contact Email NOT Deleted');

        Test.stopTest();
        
    } // End Method: testTriggers()

} // End Class