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
global class EngagementBatch_ContactReferrals implements Database.Batchable<sObject>, Schedulable
{
    public String query;
    
    global EngagementBatch_ContactReferrals() 
    {
        
        //Get the last run date
        String lastRunDate = EngagementBatch_Utility.getLastRunDate();
    
        this.query = 'SELECT Id, EngagementProfile__c, Referred_By__c, Referred_By__r.EngagementProfile__c FROM Contact ';
        this.query += ' WHERE Referred_By__c != null AND LastModifiedDate >= ' + lastRunDate + ' ';
        if(!Test.isRunningTest()) {
            this.query += ' AND Referred_By__r.EngagementProfile__r.Flag_for_Recalc__c = false';
        }
        this.query += ' AND Referred_By__r.EngagementProfile__c != null';
        if(Test.isRunningTest())
        {
            this.query += ' LIMIT 200' ;
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) 
    {
    	//Unique to this job - we need to set the date/time we started this batch/chaining process
        FPI_AppSettings__c startProcessAppSetting = FPI_AppSettings__c.getInstance('EngagementBatch_StartProcessDate');
		startProcessAppSetting.Value_DateTime__c = DateTime.now();
		update startProcessAppSetting;

    	return Database.getQueryLocator(query);
    }

    //EngagementBatch_ContactReferrals should be the only one with a SchedulableContext - we don't want to schedule the others
    global void execute(SchedulableContext sc) 
    {
        EngagementBatch_ContactReferrals b = new EngagementBatch_ContactReferrals(); 
        database.executebatch(b, EngagementBatch_Utility.getBatchSize('EngmtBatch_ContactReferrals_BatchSize'));
   }

    global void execute(Database.BatchableContext BC, List<Contact> scope) 
    {
        Set<Id> epIds = new Set<Id>();
        List<EngagementProfile__c> epList = new List<EngagementProfile__c>();

        for(Contact record : scope ) {
            epIds.add(record.Referred_By__r.EngagementProfile__c);
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
            EngagementBatch_Transactions batchClass = new EngagementBatch_Transactions();
            database.executebatch(batchClass, EngagementBatch_Utility.getBatchSize('EngmtBatch_Transactions_BatchSize'));
        }
    }
}