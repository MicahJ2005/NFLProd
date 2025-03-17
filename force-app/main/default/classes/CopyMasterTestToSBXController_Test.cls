@isTest
private class CopyMasterTestToSBXController_Test {
	@isTest static void doTest(){
        UnitTest_Test_Data.commitFPIApexSettings();
        
        //Need the following...
        //1. Account
        //2. Opportunity
        //3. Master Test
        //4. Quota / Master Quotas
        //5. Sessions
        //  5.5.    Related Session
        //6. Session Quotas

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

        //We need to query for everything under the myMT to ensure the fields are there...
        //Build out the query with every field possible!
        CopyMasterTestToSBXController cntrlr = new CopyMasterTestToSBXController();
        List<String> skipFields = new List<String>();
        List<String> selectFields = cntrlr.editableFields('Master_Test__c', skipFields);
        String qry = 'SELECT Id, Opportunity__r.AccountId, ' + String.join(selectFields,',') + ' FROM Master_Test__c WHERE Id = \'' + myMT.Id + '\' ';
        List<Master_Test__c> myList = Database.query(qry);
        myMT = myList[0];

        Test.startTest();
			PageReference pageRef = Page.CopyMasterTestToSBX;
			Test.setCurrentPage(pageRef);
			ApexPages.StandardController sc = new ApexPages.StandardController(myMT);
            CopyMasterTestToSBXController stdCntrlr = new CopyMasterTestToSBXController(sc);
            stdCntrlr.postMasterTestToSBX();
		Test.stopTest();

        //THEN - need to update each of the records to have "Sandbox_Salesforce_Id__c" so it's treated as an update
        customerAccount.Sandbox_Salesforce_Id__c = customerAccount.Id;
        testingLocationAccount.Sandbox_Salesforce_Id__c = testingLocationAccount.Id;
        update new List<Account>{customerAccount, testingLocationAccount};
        
        myMT.sandbox_salesforce_id__c = myMT.Id;
        update myMT;

        List<Quota__c> updateMQs = new List<Quota__c>();
        List<Session__c> updateSessions = new List<Session__c>();
        List<Session_Quota__c> updateSQs = new List<Session_Quota__c>();

        for(Quota__c q : [SELECT Id FROM Quota__c]) {
            q.Sandbox_Salesforce_Id__c = q.Id;
            updateMQs.add(q);
        }
        for(Session__c s : [SELECT Id FROM Session__c]) {
            s.Sandbox_Salesforce_Id__c = s.Id;
            updateSessions.add(s);
        }
        for(Session_Quota__c sq : [SELECT Id FROM Session_Quota__c]) {
            sq.Sandbox_Salesforce_Id__c = sq.Id;
            updateSQs.add(sq);
        }
        update updateMQs;
        update updateSessions;
        update updateSQs;
        
        stdCntrlr.postMasterTestToSBX();

	}
}