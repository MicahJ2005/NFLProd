@isTest
private class UnitTest_Tasteocracy_EmailComponentCntlr {
	static testMethod void testFormattedOrdinal() {
        Tasteocracy_EmailComponentController cntrlr = new Tasteocracy_EmailComponentController();

        //Need a contact with TR records
        UnitTest_Test_Data.commitFPIApexSettings(true);
       
        Account customerAccount = UnitTest_Test_Data.buildTestAccount('Eurofins Client', userInfo.getUserId());
        insert customerAccount;

        Account testingLocationAccount = UnitTest_Test_Data.buildTestAccount('Local Testing Location', userInfo.getUserId());
        insert testingLocationAccount;

        Master_Test__c myMT = UnitTest_Test_Data.BuildMasterTest();
        insert myMT;

        UnitTest_Test_Data.buildMQ_Session_SQs(myMT.Id, testingLocationAccount.Id);

        Contact testContactAdult = UnitTest_Test_data.createRespondent();

        //This respondent/contact now needs a head of household record and TR records
        Test_Respondent__c tr = UnitTest_Test_data.BuildTestRespondent(testContactAdult.Id, myMT.Id);
        tr.Tested_Status__c = 'Tested';
        tr.Check_Amount__c = 25;
        tr.Tested_Status__c = 'No Show';
        insert tr;

        cntrlr.contactId = testContactAdult.Id;
        cntrlr.getFormattedOrdinal();


        Master_Test__c myMT2 = UnitTest_Test_Data.BuildMasterTest();
        insert myMT2;

        UnitTest_Test_Data.buildMQ_Session_SQs(myMT2.Id, testingLocationAccount.Id);

        //This respondent/contact now needs a head of household record and TR records
        Test_Respondent__c tr2 = UnitTest_Test_data.BuildTestRespondent(testContactAdult.Id, myMT2.Id);
        tr2.Tested_Status__c = 'Tested';
        tr2.Check_Amount__c = 25;
        tr2.Tested_Status__c = 'No Show';
        insert tr2;

        cntrlr.getFormattedOrdinal();
    }

    static testMethod void testFormattedDateTime() {
        Tasteocracy_EmailComponentController cntrlr = new Tasteocracy_EmailComponentController();

        cntrlr.dateTimeToUse = DateTime.now();
        cntrlr.dateFormatToUse = 'EEE M/d/yyyy h:mm a';
        cntrlr.brandToUse = 'Plymouth';
        cntrlr.getFormattedDatetime();

        cntrlr.brandToUse = 'Livermore';
        cntrlr.getFormattedDatetime();

        cntrlr.brandToUse = 'BoundBrook';
        cntrlr.getFormattedDatetime();

        cntrlr.dateTimeToUse = null;
        cntrlr.getFormattedDatetime();

        cntrlr.dateTimeToUse = DateTime.now();
        cntrlr.dateFormatToUse = null;
        cntrlr.getFormattedDatetime();
    }

    static testMethod void testFormattedGreeting() {
        Tasteocracy_EmailComponentController cntrlr = new Tasteocracy_EmailComponentController();

        cntrlr.useCase = 'Example Pairs';
        cntrlr.trName = 'Respondent Name';
        cntrlr.schedName = 'Scheduler Name';
        cntrlr.getFormattedGreeting();

        cntrlr.useCase = 'Example Child';
        cntrlr.getFormattedGreeting();

        cntrlr.useCase = 'Example Adult';
        cntrlr.getFormattedGreeting();
        
        cntrlr.useCase = null;
        cntrlr.trName = null;
        cntrlr.schedName = null;
        cntrlr.getFormattedGreeting();
    }
}