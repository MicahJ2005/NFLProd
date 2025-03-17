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
private class UnitTest_Contact_Triggers {

                                                 // Private Variables
    private static final String fpiRespondent_ADULT = 'Adult-Respondent';
    private static final String fpiRespondent_CHILD = 'Child-Respondent';

    static testMethod void testTriggers() {
        // TO DO: implement unit test
        User testuser = UnitTest_Test_data.buildTestUser(1, 'System Administrator');
        insert testuser;

        UnitTest_Test_Data.commitFPIApexSettings(true);
        
        Account testAccount = UnitTest_Test_data.buildTestAccount('Eurofins Client', testUser.Id);
        insert testAccount;
        
        //Account testAccountR = UnitTest_Test_data.buildTestAccount('Respondent Master Account', testUser.Id);
        //insert testAccountR;
        
        //FPI_AppSettings__c testAppSetting1 = UnitTest_Test_data.BuildFPI_AppSettings(testAccountR.Id, 'ID_RespondentAccount');
        //insert testAppSetting1;
        
        //FPI_AppSettings__c testAppSetting2 = UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactBusiness', 'Eurofins Client Contact', 'Contact');
        //insert testAppSetting2;
        
        //FPI_AppSettings__c testAppSetting3 = UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactRespondentAdult', 'Adult-Respondent', 'Contact');
        //insert testAppSetting3;
        
        Contact testContact = UnitTest_Test_data.BuildContact(1, testUser.Id, testaccount.Id, 'Eurofins Client Contact');
        
        Test.startTest();
            insert testContact;


            silverpop__Silverpop_Email_Activity__c spEA = new silverpop__Silverpop_Email_Activity__c();
            spEA.silverpop__Contact__c = testContact.Id;
            spEA.silverpop__Status__c = 'Bounced';
            insert spEA;

            //07.30.2021 - deleting the contact - to cover the delete method in the contact trigger
            delete testContact;

        Test.stopTest();
    }

    /*******************************************************************************
     * testAfterUpdate
     * @Description: Method to test the "afterUpdate" trigger.
     * 
     * @Date: 03/22/2016
     * @Author: Jason Flippen (Demand Chain Systems)
     * 
     * @Updates: N/A
     *******************************************************************************/
    static testMethod void testAfterUpdate()
    {
        User testUser = UnitTest_Test_data.buildTestUser(1, 'System Administrator');
        insert(testUser);

        //Setup the custom settings
        UnitTest_Test_Data.commitFPIApexSettings();

        Account testAccount = UnitTest_Test_data.buildTestAccount('Respondent Master Account', testUser.Id);
        insert(testAccount);
        
        Contact testContactAdult = UnitTest_Test_data.BuildContact(1, testUser.Id, testAccount.Id, fpiRespondent_ADULT);
        testContactAdult.Email = 'testadult@tester.com';
        insert(testContactAdult);
        
        Contact testContactChild = UnitTest_Test_data.BuildContact(1, testUser.Id, testAccount.Id, fpiRespondent_CHILD);
        testContactChild.Email = 'testchild@tester.com';
        insert(testContactChild);
        
        Household__c testHousehold = new Household__c();
        testHousehold.Head_of_Household__c = testContactAdult.Id;
        insert(testHousehold);

        Household_Contact__c testHHContactAdult = new Household_Contact__c();
        testHHContactAdult.Household__c = testHousehold.Id;
        testHHContactAdult.Contact__c = testContactAdult.Id;
        insert(testHHContactAdult);

        Household_Contact__c testHHContactChild = new Household_Contact__c();
        testHHContactChild.Household__c = testHousehold.Id;
        testHHContactChild.Contact__c = testContactChild.Id;
        insert(testHHContactChild);


        system.runAs(testUser)
        {
            Test.startTest();

                testContactAdult.Email = 'testadultnew@tester.com';
                update(testContactAdult);

                                                 // Check to make sure the Household
                                                 // Contact Email was updated on
                                                 // the Child Contact.
                List<Contact> updatedContList = [SELECT Id
                                                 FROM   Contact
                                                 WHERE  Id = :testContactChild.Id
                                                 AND    Household_Contact_Email__c = 'testadultnew@tester.com'];
               
            System.assert(updatedContList.size() > 0, 'Child Contact NOT Updated');
           
            Test.stopTest();
        }
    }
}