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
* database.executebatch(b, 100);
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
global class EngagementBatch_Transactions implements Database.Batchable<sObject>
{
    public String query;
    
    global EngagementBatch_Transactions() 
    {
        //Get the last run date
        String lastRunDate = EngagementBatch_Utility.getLastRunDate();

        this.query = 'SELECT Id, EngagementProfile__r.Respondent__c FROM EngagementTransaction__c ';
        this.query += ' WHERE LastModifiedDate >= ' + lastRunDate + ' ';
        if(!Test.isRunningTest()) {
            this.query += ' AND EngagementProfile__r.Flag_for_Recalc__c = false';
        }
        if(Test.isRunningTest())
        {
            this.query += ' LIMIT 200' ;
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) 
    {
    	return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<EngagementTransaction__c> scope) 
    {
        List<EngagementProfile__c> epList = new List<EngagementProfile__c>();
        Set<Id> epIds = new Set<Id>();

        for(EngagementTransaction__c record : scope ) {
            epIds.add(record.EngagementProfile__c);
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
            EngagementBatch_TestRespondents batchClass = new EngagementBatch_TestRespondents();
            database.executebatch(batchClass, EngagementBatch_Utility.getBatchSize('EngmtBatch_TestRespondents_BatchSize'));
        }
    }
}