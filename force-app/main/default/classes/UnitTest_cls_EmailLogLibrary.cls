@isTest
private class UnitTest_cls_EmailLogLibrary {

    @testSetup static void setupMyTest() {
        User testuser = UnitTest_Test_data.buildTestUser(1, 'System Administrator');
        insert testuser;

        UnitTest_Test_data.commitFPIApexSettings();
        
        Account testAccountR = UnitTest_Test_data.buildTestAccount('Respondent Master Account', testUser.Id);
        insert testAccountR;
        
        FPI_AppSettings__c testAppSetting1 = UnitTest_Test_data.BuildFPI_AppSettings(testAccountR.Id, 'ID_RespondentAccount');
        insert testAppSetting1;
        
        FPI_AppSettings__c testAppSetting2 = UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactBusiness', 'Eurofins Client Contact', 'Contact');
        insert testAppSetting2;
        
        FPI_AppSettings__c testAppSetting3 = UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactRespondentAdult', 'Adult-Respondent', 'Contact');
        insert testAppSetting3;
        
        Contact testContact_Adult = UnitTest_Test_data.BuildContact(1, testUser.Id, testAccountR.Id, 'Adult-Respondent');
        testContact_Adult.Birthdate = Date.newInstance(1980, 1, 1);
        insert testContact_Adult;
        
        Contact testContact_Child = UnitTest_Test_data.BuildContact(1, testUser.Id, testAccountR.Id, 'Child-Respondent');
        testContact_Child.Birthdate = Date.newInstance(Date.Today().year()-6, 1, 1);
        insert testContact_Child;
       
        Master_Test__c testMasterTest = UnitTest_Test_data.BuildMasterTest();
        insert testMasterTest;
       
        Master_Test__c testMasterTest_Pairs = UnitTest_Test_data.BuildMasterTest();
        testMasterTest_Pairs.Pairs_Test__c = true;
        insert testMasterTest_Pairs;

        Session__c sesQuant = new Session__c(Related_Test__c=testMasterTest.Id);
        sesQuant.Research_Type__c = 'Quant';
        sesQuant.Session_Start__c = System.Now().addHours(48); //2 days out
        sesQuant.Session_End__c = System.Now().addHours(49);
        sesQuant.Check_Amount__c = 42.00;
        insert sesQuant;

        Quota__c mtQuota = new Quota__c(Related_Test__c=testMasterTest.Id);
        mtQuota.IsOpen__c = true;
        mtQuota.Beacon_Condition__c = 'conditionsTestMethod';
        mtQuota.IsTrackingOnly__c = false;
        insert mtQuota;

        Session_Quota__c sqQuant = new Session_Quota__c(Master_Quota__c=mtQuota.Id,Related_Session__c=sesQuant.Id);
        sqQuant.IsOpen__c = true;
        insert sqQuant;
    }
    
    @isTest static void emailLogs_AgainstTRs() {
        //49% coverage...
        
        Master_Test__c testMasterTest = [SELECT Id FROM Master_Test__c WHERE Pairs_Test__c = false LIMIT 1];
        Master_Test__c testMasterTest_Pairs = [SELECT Id FROM Master_Test__c WHERE Pairs_Test__c = true LIMIT 1];
        Contact testContact_Adult = [SELECT Id FROM Contact WHERE Age__c >= 18 LIMIT 1];
        Contact testContact_Child = [SELECT Id FROM Contact WHERE Age__c < 18 LIMIT 1];
        
        Set<Id> trIDs = new Set<Id>();
        List<Test_Respondent__c> trList = new List<Test_Respondent__c>();
        Map<Id, Test_Respondent__c> trMap = new Map<Id, Test_Respondent__c>();
        
        //FPI Cancellation Adult
        Test_Respondent__c testRespondent1 = UnitTest_Test_data.BuildTestRespondent(testContact_Adult.Id, testMasterTest.Id);
        testRespondent1.Respondent_Status__c = 'FPI Canceled';
        //insert testRespondent1;
        trList.add(testRespondent1);
        
        //FPI Cancellation Child
        Test_Respondent__c testRespondent2 = UnitTest_Test_data.BuildTestRespondent(testContact_Child.Id, testMasterTest.Id);
        testRespondent2.Respondent_Status__c = 'FPI Canceled';
        //insert testRespondent2;
        trList.add(testRespondent2);
        
        //FPI Cancellation Pairs
        Test_Respondent__c testRespondent3 = UnitTest_Test_data.BuildTestRespondent(testContact_Adult.Id, testMasterTest_Pairs.Id);
        testRespondent3.Respondent_Status__c = 'FPI Canceled';
        //insert testRespondent3;
        trList.add(testRespondent3);
        
        //No Show Adult
        Test_Respondent__c testRespondent4 = UnitTest_Test_data.BuildTestRespondent(testContact_Adult.Id, testMasterTest.Id);
        testRespondent4.Respondent_Status__c = 'Scheduled';
        testRespondent4.Tested_Status__c = 'No Show';
        testRespondent4.Session_Type__c = 'Something Else';
        //insert testRespondent4;
        trList.add(testRespondent4);
        
        //No Show Adult HUT
        Test_Respondent__c testRespondent5 = UnitTest_Test_data.BuildTestRespondent(testContact_Adult.Id, testMasterTest.Id);
        testRespondent5.Respondent_Status__c = 'Scheduled';
        testRespondent5.Tested_Status__c = 'No Show';
        testRespondent5.Session_Type__c = 'HUT - Home Use Test';
        //insert testRespondent5;
        trList.add(testRespondent5);
        
        //No Show Child
        Test_Respondent__c testRespondent6 = UnitTest_Test_data.BuildTestRespondent(testContact_Child.Id, testMasterTest.Id);
        testRespondent6.Respondent_Status__c = 'Scheduled';
        testRespondent6.Tested_Status__c = 'No Show';
        testRespondent6.Session_Type__c = 'Something Else';
        //insert testRespondent6;
        trList.add(testRespondent6);
        
        //No Show Child HUT
        Test_Respondent__c testRespondent7 = UnitTest_Test_data.BuildTestRespondent(testContact_Child.Id, testMasterTest.Id);
        testRespondent7.Respondent_Status__c = 'Scheduled';
        testRespondent7.Tested_Status__c = 'No Show';
        testRespondent7.Session_Type__c = 'HUT - Home Use Test';
        //insert testRespondent7;
        trList.add(testRespondent7);
        
        //Scheduled for Call Back Adult
        Test_Respondent__c testRespondent8 = UnitTest_Test_data.BuildTestRespondent(testContact_Adult.Id, testMasterTest.Id);
        testRespondent8.Respondent_Status__c = 'Prequalified Unscheduled';
        testRespondent8.Session_Date__c = Date.today().addDays(2);
        //insert testRespondent8;
        trList.add(testRespondent8);
        
        //Scheduled for Call Back Child
        Test_Respondent__c testRespondent9 = UnitTest_Test_data.BuildTestRespondent(testContact_Child.Id, testMasterTest.Id);
        testRespondent9.Respondent_Status__c = 'Prequalified Unscheduled';
        testRespondent9.Session_Date__c = Date.today().addDays(2);
        //insert testRespondent9;
        trList.add(testRespondent9);
        
        //Scheduled for Call Back Pairs
        Test_Respondent__c testRespondent10 = UnitTest_Test_data.BuildTestRespondent(testContact_Adult.Id, testMasterTest_Pairs.Id);
        testRespondent10.Respondent_Status__c = 'Prequalified Unscheduled';
        testRespondent10.Session_Date__c = Date.today().addDays(2);
        //insert testRespondent10;
        trList.add(testRespondent10);
        
        insert trList;
        for(Test_Respondent__c tr : trList) {
            trIDs.add(tr.Id);
            trMap.put(tr.Id, tr);
        }
        
        //This will run the Email Logs against the Test Respondents, not the TRQs
        EmailLogLibrary.processTR(trIDs, trMap);
	}
    
    @isTest static void emailLogs_AgainstTRQs() {
        
        Master_Test__c testMasterTest = [SELECT Id FROM Master_Test__c WHERE Pairs_Test__c = false LIMIT 1];
        Master_Test__c testMasterTest_Pairs = [SELECT Id FROM Master_Test__c WHERE Pairs_Test__c = true LIMIT 1];
        Contact testContact_Adult = [SELECT Id FROM Contact WHERE Age__c >= 18 LIMIT 1];
        Contact testContact_Child = [SELECT Id FROM Contact WHERE Age__c < 18 LIMIT 1];
        Session_Quota__c testSQ = [SELECT Id, Related_Session__c FROM Session_Quota__c WHERE IsOpen__c = true LIMIT 1];
        
        Set<Id> trIDs = new Set<Id>();
        List<Test_Respondent__c> trList = new List<Test_Respondent__c>();
        List<Test_Respondent_Quota__c> trqList = new List<Test_Respondent_Quota__c>();
        Map<Id, Test_Respondent__c> trMap = new Map<Id, Test_Respondent__c>();
        
        //Reminder / Scheduled Email Adult
        Test_Respondent__c testRespondent1 = UnitTest_Test_data.BuildTestRespondent(testContact_Adult.Id, testMasterTest.Id);
        testRespondent1.Respondent_Status__c = 'Scheduled';
        testRespondent1.Tested_Status__c = 'Pending';
        insert testRespondent1;
        trList.add(testRespondent1);
        
        Test_Respondent_Quota__c trq1 = UnitTest_Test_data.BuildTRQ(testRespondent1.Id, testSQ.Id);
        trq1.IsQualified__c = true;
        trq1.IsScheduled__c = true;
        trqList.add(trq1);
        
        //Reminder / Scheduled Email Child
        Test_Respondent__c testRespondent2 = UnitTest_Test_data.BuildTestRespondent(testContact_Child.Id, testMasterTest.Id);
        testRespondent2.Respondent_Status__c = 'Scheduled';
        testRespondent2.Tested_Status__c = 'Pending';
        insert testRespondent2;
        trList.add(testRespondent2);
        
        Test_Respondent_Quota__c trq2 = UnitTest_Test_data.BuildTRQ(testRespondent2.Id, testSQ.Id);
        trq2.IsQualified__c = true;
        trq2.IsScheduled__c = true;
        trqList.add(trq2);
        
        //Reminder / Scheduled Email Pairs
        Test_Respondent__c testRespondent3 = UnitTest_Test_data.BuildTestRespondent(testContact_Adult.Id, testMasterTest_Pairs.Id);
        testRespondent3.Respondent_Status__c = 'FPI Canceled';
        insert testRespondent3;
        trList.add(testRespondent3);
        
        Test_Respondent_Quota__c trq3 = UnitTest_Test_data.BuildTRQ(testRespondent3.Id, testSQ.Id);
        trq3.IsQualified__c = true;
        trq3.IsScheduled__c = true;
        trqList.add(trq3);
        
        //Cancellation Adult
        Test_Respondent__c testRespondent4 = UnitTest_Test_data.BuildTestRespondent(testContact_Adult.Id, testMasterTest.Id);
        testRespondent4.Respondent_Status__c = 'Qualified';
        insert testRespondent4;
        trList.add(testRespondent4);
        
        //for this one - the respondent status needs to change...
        testRespondent4.Respondent_Status__c = 'Scheduled';
        testRespondent4.Session_ID__c = testSQ.Related_Session__c;
        
        Test_Respondent_Quota__c trq4 = UnitTest_Test_data.BuildTRQ(testRespondent4.Id, testSQ.Id);
        trq4.IsQualified__c = true;
        trq4.IsScheduled__c = false;
        trqList.add(trq4);
        
        //Cancellation Child
        Test_Respondent__c testRespondent5 = UnitTest_Test_data.BuildTestRespondent(testContact_Child.Id, testMasterTest.Id);
        testRespondent5.Respondent_Status__c = 'Qualified';
        insert testRespondent5;
        trList.add(testRespondent5);
        
        //for this one - the respondent status needs to change...
        testRespondent5.Respondent_Status__c = 'Scheduled';
        testRespondent5.Session_ID__c = testSQ.Related_Session__c;
        
        Test_Respondent_Quota__c trq5 = UnitTest_Test_data.BuildTRQ(testRespondent5.Id, testSQ.Id);
        trq5.IsQualified__c = true;
        trq5.IsScheduled__c = false;
        trqList.add(trq5);
        
        //Cancellation Pairs
        Test_Respondent__c testRespondent6 = UnitTest_Test_data.BuildTestRespondent(testContact_Adult.Id, testMasterTest_Pairs.Id);
        testRespondent6.Respondent_Status__c = 'Qualified';
        insert testRespondent6;
        trList.add(testRespondent6);
        
        //for this one - the respondent status needs to change...
        testRespondent6.Respondent_Status__c = 'Scheduled';
        testRespondent6.Session_ID__c = testSQ.Related_Session__c;
        
        Test_Respondent_Quota__c trq6 = UnitTest_Test_data.BuildTRQ(testRespondent6.Id, testSQ.Id);
        trq6.IsQualified__c = true;
        trq6.IsScheduled__c = false;
        trqList.add(trq6);
        
        insert trqList;
        for(Test_Respondent__c tr : trList) {
            trIDs.add(tr.Id);
            trMap.put(tr.Id, tr);
        }
        
        //This will run the Email Logs against the Test Respondents, AND the TRQs
        EmailLogLibrary.processTR(trIDs, trMap);
	}
}