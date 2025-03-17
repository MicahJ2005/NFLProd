@isTest
private class ContactLibrary_Test {

    @isTest static void doTest(){
        UnitTest_Test_Data.commitFPIApexSettings(true);
       
        Account customerAccount = UnitTest_Test_Data.buildTestAccount('Eurofins Client', userInfo.getUserId());
        insert customerAccount;

        Account testingLocationAccount = UnitTest_Test_Data.buildTestAccount('Local Testing Location', userInfo.getUserId());
        insert testingLocationAccount;

        Opportunity customerOpp = UnitTest_Test_Data.BuildOpportunity(customerAccount.Id, 'Consumer Research Opportunity', 'Closed Won');
        insert customerOpp;

        Master_Test__c myMT = UnitTest_Test_Data.BuildMasterTest();
        myMT.Opportunity__c = customerOpp.Id;
        insert myMT;

        UnitTest_Test_Data.buildMQ_Session_SQs(myMT.Id, testingLocationAccount.Id);

        Contact testContactAdult = UnitTest_Test_data.createRespondent();

        //This respondent/contact now needs a head of household record and TR records
        Test_Respondent__c tr = UnitTest_Test_data.BuildTestRespondent(testContactAdult.Id, myMT.Id);
        tr.Tested_Status__c = 'Tested';
        tr.Check_Amount__c = 25;
        insert tr;

        Session_Quota__c sq = [SELECT Id, Related_Session__c FROM Session_Quota__c WHERE Master_Quota__r.Related_Test__c = :myMT.Id LIMIT 1];
        Test_Respondent_Quota__c trq = UnitTest_Test_data.BuildTRQ(tr.Id, sq.Id);
        trq.IsScheduled__c = true;
        insert trq;

        Household__c hseHold = UnitTest_Test_data.createHouseholdAndHouseholdContact(testContactAdult.Id);
        
        Set<Id> setContactIds = new Set<Id>();
        setContactIds.add(testContactAdult.Id);

        Set<Id> setTRQIds = new Set<Id>();
        setTRQIds.add(trq.Id);

        ContactLibrary.rollupSummaryDates(setContactIds, true);
        ContactLibrary.rollupQuantQual(setTRQIds);

        Session__c sess = new Session__c(Id = sq.Related_Session__c);
        Time myTime = Time.newInstance(3, 3, 3, 0);
        Time myTime2 = Time.newInstance(4, 3, 3, 0);
        sess.Session_Start__c = DateTime.newInstance(Date.today().addDays(1), myTime);
        sess.Session_End__c = DateTime.newInstance(Date.today().addDays(1), myTime2);
        sess.Research_Type__c = 'Quant';
        update sess;

        testContactAdult.Email = 'somethingelse@test.com';
        testContactAdult.Send_IBM_Callout__c = true;
        testContactAdult.SMS_Opt_in_Date__c = Date.today();
        testContactAdult.MobilePhone = '222-222-2222';
        update testContactAdult;
        ContactLibrary.rollupSummaryDates(setContactIds, true);

        sess.Session_Start__c = DateTime.newInstance(Date.today().addDays(-3), myTime);
        sess.Session_End__c = DateTime.newInstance(Date.today().addDays(-3), myTime2);
        sess.Research_Type__c = 'Quant';
        update sess;
        ContactLibrary.rollupSummaryDates(setContactIds, true);

        sess.Session_Start__c = DateTime.newInstance(Date.today().addDays(-3), myTime);
        sess.Session_End__c = DateTime.newInstance(Date.today().addDays(-3), myTime2);
        sess.Research_Type__c = 'Qual';
        update sess;
        ContactLibrary.rollupSummaryDates(setContactIds, true);

    }
    
    @isTest static void doTest2_rollupSummary(){
        UnitTest_Test_Data.commitFPIApexSettings(true);
       
        Account customerAccount = UnitTest_Test_Data.buildTestAccount('Eurofins Client', userInfo.getUserId());
        insert customerAccount;

        Account testingLocationAccount = UnitTest_Test_Data.buildTestAccount('Local Testing Location', userInfo.getUserId());
        insert testingLocationAccount;

        Opportunity customerOpp = UnitTest_Test_Data.BuildOpportunity(customerAccount.Id, 'Consumer Research Opportunity', 'Closed Won');
        insert customerOpp;

        Master_Test__c myMT = UnitTest_Test_Data.BuildMasterTest();
        myMT.Opportunity__c = customerOpp.Id;
        insert myMT;

        UnitTest_Test_Data.buildMQ_Session_SQs(myMT.Id, testingLocationAccount.Id);

        Contact testContactAdult = UnitTest_Test_data.createRespondent();
        System.debug('DC-TEST: ' + testContactAdult.RecordTypeId);

        //This respondent/contact now needs a head of household record and TR records
        Test_Respondent__c tr = UnitTest_Test_data.BuildTestRespondent(testContactAdult.Id, myMT.Id);
        tr.Tested_Status__c = 'Tested';
        tr.Check_Amount__c = 25;
        
        Test_Respondent__c tr2 = UnitTest_Test_data.BuildTestRespondent(testContactAdult.Id, myMT.Id);
        tr2.Tested_Status__c = 'Cancelled';
        
        Test_Respondent__c tr3 = UnitTest_Test_data.BuildTestRespondent(testContactAdult.Id, myMT.Id);
        tr3.Tested_Status__c = 'No Show';
        
        Test_Respondent__c tr4 = UnitTest_Test_data.BuildTestRespondent(testContactAdult.Id, myMT.Id);
        tr4.Tested_Status__c = 'Tardy Not Paid';
        
        Test_Respondent__c tr5 = UnitTest_Test_data.BuildTestRespondent(testContactAdult.Id, myMT.Id);
        tr5.Tested_Status__c = 'PSA';
        
        List<Test_Respondent__c> trInsertList = new List<Test_Respondent__c>();
        trInsertList.add(tr);
        trInsertList.add(tr2);
        trInsertList.add(tr3);
        trInsertList.add(tr4);
        trInsertList.add(tr5);
        insert trInsertList;
        
        Session_Quota__c sq = [SELECT Id FROM Session_Quota__c WHERE Master_Quota__r.Related_Test__c = :myMT.Id LIMIT 1];
        Test_Respondent_Quota__c trq = UnitTest_Test_data.BuildTRQ(tr.Id, sq.Id);
        trq.IsScheduled__c = true;
        insert trq;

        Household__c hseHold = UnitTest_Test_data.createHouseholdAndHouseholdContact(testContactAdult.Id);
        
        Set<Id> setContactIds = new Set<Id>();
        setContactIds.add(testContactAdult.Id);

        Set<Id> setTRQIds = new Set<Id>();
        setTRQIds.add(trq.Id);

        ContactLibrary.rollupSummary(setContactIds);
	}
}