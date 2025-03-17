/**
* Batch job to determine engagement profiles that need their items recalculated
*
* Schedule/run EngagementBatch_ContactReferrals
* When that finishes it will call EngagementBatch_Transactions
* When that finishes it will call EngagementBatch_TestRespondents
* When that finishes it will call EngagementBatch_ProcessRecalcs
*
* To Run from Dev Console: 
* EngagementBatch_ContactReferrals b = new EngagementBatch_ContactReferrals(); 
  database.executebatch(b, 100);
*
* Custom Settings - in FPI Application Settings that are referenced throughout the jobs
*        EngagementBatch_LastProcessDate
*        EngagementBatch_StartProcessDate
*        EngmtBatch_ContactReferrals_BatchSize
*        EngmtBatch_Transactions_BatchSize
*        EngmtBatch_TestRespondents_BatchSize
*        EngmtBatch_ProcessRecalcs_BatchSize
* 
* @Date: 	02.08.2024
* @Author: 	Sophia Murphy (Demand Chain)
*
* Change Log
* ---------------------------------------------------
* 
* 
*/
global class EngagementBatch_TestRespondents implements Database.Batchable<sObject>
{
    public String query;
    
    global EngagementBatch_TestRespondents() 
    {
        //Get the last run date
        String lastRunDate = EngagementBatch_Utility.getLastRunDate();

        this.query = 'SELECT Id, Respondent__c, Respondent__r.EngagementProfile__c FROM Test_Respondent__c ';
        this.query += ' WHERE LastModifiedDate >= ' + lastRunDate + ' ';
        if(!Test.isRunningTest()) {
            this.query += ' AND Respondent__r.EngagementProfile__r.Flag_for_Recalc__c = false';
        }
        this.query += ' AND Respondent__c != null';
        if(Test.isRunningTest())
        {
            this.query += ' LIMIT 200' ;
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) 
    {
    	return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Test_Respondent__c> scope) 
    {
        Set<Id> epIds = new Set<Id>();
        List<EngagementProfile__c> epList = new List<EngagementProfile__c>();
        for(Test_Respondent__c record : scope ) {
            if(record.Respondent__r.EngagementProfile__c != null) {
                epIds.add(record.Respondent__r.EngagementProfile__c);
            }
        }
        for(Id epId : epIds) {
            EngagementProfile__c epTemp = new EngagementProfile__c(Id = epId);
            epTemp.Flag_for_Recalc__c = true;
            epList.add(epTemp);
        }
        if(epList.size() > 0) {
           update epList;
        }
    }

    global void finish(Database.BatchableContext BC) 
    {
        if(!EngagementBatch_Utility.jobsAreRunning()) {
            //start the next batch...
            EngagementBatch_ProcessRecalcs batchClass = new EngagementBatch_ProcessRecalcs();
            database.executebatch(batchClass, EngagementBatch_Utility.getBatchSize('EngmtBatch_ProcessRecalcs_BatchSize'));
        }
    }
}