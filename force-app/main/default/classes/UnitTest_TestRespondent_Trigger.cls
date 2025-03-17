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
private class UnitTest_TestRespondent_Trigger {

    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        User testuser = UnitTest_Test_data.buildTestUser(1, 'System Administrator');
        insert testuser;

        UnitTest_Test_data.commitFPIApexSettings();
        
        Account testAccount = UnitTest_Test_data.buildTestAccount('Eurofins Client', testUser.Id);
        insert testAccount;
        
        Account testAccountR = UnitTest_Test_data.buildTestAccount('Respondent Master Account', testUser.Id);
        insert testAccountR;
        
        FPI_AppSettings__c testAppSetting1 = UnitTest_Test_data.BuildFPI_AppSettings('ID_RespondentAccount', testAccountR.Id);
        insert testAppSetting1;
        
        //FPI_AppSettings__c testAppSetting2 = UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactBusiness', 'Eurofins Client Contact', 'Contact');
        //insert testAppSetting2;
        
        //FPI_AppSettings__c testAppSetting3 = UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactRespondentAdult', 'Adult-Respondent', 'Contact');
        //insert testAppSetting3;
        
        Contact testContact = UnitTest_Test_data.BuildContact(1, testUser.Id, testaccount.Id, 'Eurofins Client Contact');
        insert testContact;
        
        Contact testContactR = UnitTest_Test_data.BuildContact(1, testUser.Id, testAccountR.Id, 'Adult-Respondent');
        insert testContactR;
       
        Master_Test__c testMasterTest = UnitTest_Test_data.BuildMasterTest();
        insert testMasterTest;

        Session__c sesQuant = new Session__c(Related_Test__c=testMasterTest.Id);
        sesQuant.Research_Type__c = 'Quant';
        sesQuant.Session_Start__c = System.Now();
        sesQuant.Session_End__c = System.Now().addHours(1);
        sesQuant.Check_Amount__c = 42.00;
        insert sesQuant;

        Quota__c mtQuota = new Quota__c(Related_Test__c=testMasterTest.Id);
        mtQuota.IsOpen__c = true;
        mtQuota.Beacon_Condition__c = 'conditionsTestMethod';
        insert mtQuota;

        Session_Quota__c sqQuant = new Session_Quota__c(Master_Quota__c=mtQuota.Id,Related_Session__c=sesQuant.Id);
        sqQuant.IsOpen__c = true;
        insert sqQuant;
        
        silverpop__Silverpop_Email_Activity__c EmailCount = new silverpop__Silverpop_Email_Activity__c ();
        	Emailcount.Name = 'Test';
        	EmailCount.silverpop__Contact__c = testContact.Id;
        insert EmailCount;
        
        Test_Respondent__c testRespondent = UnitTest_Test_data.BuildTestRespondent(testContactR.Id, testMasterTest.Id);
        	testRespondent.Tested_Status__c = 'Tested';
        	testRespondent.Check_Amount__c = 15;
        	testRespondent.Donation_Amount_Per_Event__c = 'No, $0';
        
        Test.startTest();
            insert testRespondent;
            Test_Respondent_Quota__c trqQuant = new Test_Respondent_Quota__c();
            trqQuant.Test_Respondent__c = testRespondent.Id;
            trqQuant.Session_Quota__c = sqQuant.Id;
            insert trqQuant;

            testRespondent.Tested_Status__c = 'No Show';
            testRespondent.Donation_Amount_Per_Event__c = 'Full Payment';
            update testRespondent;
            testRespondent.Tested_Status__c = 'PSA';
            testRespondent.Donation_Amount_Per_Event__c = 'Partial payment of $10';
            update testRespondent;
            testRespondent.Tested_Status__c = 'Cancelled';
            update testRespondent;

            testRespondent.Tested_Status__c = 'Tested';
            update testRespondent;

        Test.stopTest();

        // Check Contact
        //Contact conCheck = [SELECT Last_Quantitative_Participation__c, Last_Qualitative_Participation__c FROM Contact WHERE Id = :testRespondent.Respondent__c];
        //System.Assert(conCheck.Last_Qualitative_Participation__c == sesQuant.Session_Start__c.Date(), 'Last Quant didn\'t calc right!');
    }

    static testMethod void myExpressTest() {
        // TO DO: implement unit test
        User testuser = UnitTest_Test_data.buildTestUser(1, 'System Administrator');
        insert testuser;

        UnitTest_Test_data.commitFPIApexSettings();
        
        Account testAccount = UnitTest_Test_data.buildTestAccount('Eurofins Client', testUser.Id);
        insert testAccount;
        
        Account testAccountR = UnitTest_Test_data.buildTestAccount('Respondent Master Account', testUser.Id);
        insert testAccountR;
        
        FPI_AppSettings__c testAppSetting1 = UnitTest_Test_data.BuildFPI_AppSettings('ID_RespondentAccount', testAccountR.Id);
        insert testAppSetting1;
        
        //FPI_AppSettings__c testAppSetting2 = UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactBusiness', 'Eurofins Client Contact', 'Contact');
        //insert testAppSetting2;
        
        //FPI_AppSettings__c testAppSetting3 = UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactRespondentAdult', 'Adult-Respondent', 'Contact');
        //insert testAppSetting3;
        
        Contact testContact = UnitTest_Test_data.BuildContact(1, testUser.Id, testaccount.Id, 'Eurofins Client Contact');
        insert testContact;
        
        Contact testContactR = UnitTest_Test_data.BuildContact(1, testUser.Id, testAccountR.Id, 'Adult-Respondent');
        testContactR.Express_Testing_Respondent__c = false;
        insert testContactR;
       
        Master_Test__c testMasterTest = UnitTest_Test_data.BuildMasterTest();
        testMasterTest.Population_Type__c = 'Express Test';
        testMasterTest.Respondent_Type__c = 'General Testing';
        insert testMasterTest;

        Session__c sesQuant = new Session__c(Related_Test__c=testMasterTest.Id);
        sesQuant.Research_Type__c = 'Quant';
        sesQuant.Session_Start__c = System.Now();
        sesQuant.Session_End__c = System.Now().addHours(1);
        sesQuant.Check_Amount__c = 42.00;
        insert sesQuant;

        Quota__c mtQuota = new Quota__c(Related_Test__c=testMasterTest.Id);
        mtQuota.IsOpen__c = true;
        mtQuota.Beacon_Condition__c = 'conditionsTestMethod';
        insert mtQuota;

        Session_Quota__c sqQuant = new Session_Quota__c(Master_Quota__c=mtQuota.Id,Related_Session__c=sesQuant.Id);
        sqQuant.IsOpen__c = true;
        insert sqQuant;
        
        silverpop__Silverpop_Email_Activity__c EmailCount = new silverpop__Silverpop_Email_Activity__c ();
        	Emailcount.Name = 'Test';
        	EmailCount.silverpop__Contact__c = testContact.Id;
        insert EmailCount;
        
        Test_Respondent__c testRespondent = UnitTest_Test_data.BuildTestRespondent(testContactR.Id, testMasterTest.Id);
        	testRespondent.Tested_Status__c = 'Pending';
        	//testRespondent.Check_Amount__c = 15;
            //testRespondent.Donation_Amount_Per_Event__c = 'No, $0';
            testRespondent.Respondent_Status__c = 'Scheduled';
        
        Test.startTest();
            insert testRespondent;
            Test_Respondent_Quota__c trqQuant = new Test_Respondent_Quota__c();
            trqQuant.Test_Respondent__c = testRespondent.Id;
            trqQuant.Session_Quota__c = sqQuant.Id;
            insert trqQuant;

        Test.stopTest();

        // Check Contact
        //Contact conCheck = [SELECT Last_Quantitative_Participation__c, Last_Qualitative_Participation__c FROM Contact WHERE Id = :testRespondent.Respondent__c];
        //System.Assert(conCheck.Last_Qualitative_Participation__c == sesQuant.Session_Start__c.Date(), 'Last Quant didn\'t calc right!');
    }
}