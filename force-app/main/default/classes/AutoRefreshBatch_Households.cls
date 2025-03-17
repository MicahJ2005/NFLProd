/**
* Batch job to take records that have been updated in the last day and resend them to Tasteocracy
* This batch is part of a set.  
*
* Schedule/run AutoRefreshBatch_Households
* When that finishes it will call AutoRefreshBatch_Contacts
* When that finishes it will call AutoRefreshBatch_HouseholdContacts
*
* To Run from Dev Console: 
* AutoRefreshBatch_Households b = new AutoRefreshBatch_Households(); 
* database.executebatch(b, 100);
* 
* @Date: 	07.16.2020
* @Author: 	Sophia Murphy (Demand Chain)
* 
*/
global class AutoRefreshBatch_Households implements Database.Batchable<sObject>, Schedulable
{
    public String query;
    
    global AutoRefreshBatch_Households() 
    {
    	this.query = 'SELECT Id FROM Household__c WHERE LastModifiedDate >= LAST_N_DAYS:1' ;
        if(Test.isRunningTest())
        {
            this.query = 'SELECT Id FROM Household__c WHERE LastModifiedDate >= LAST_N_DAYS:1 LIMIT 200' ;
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) 
    {
    	return Database.getQueryLocator(query);
    }

    global void execute(SchedulableContext sc) 
    {
        AutoRefreshBatch_Households b = new AutoRefreshBatch_Households(); 
        database.executebatch(b, 200);
   }

    global void execute(Database.BatchableContext BC, List<Household__c> scope) 
    {
        Set<Id> idSet = new Set<Id>();
        for(Household__c hh : scope ) {
            idSet.add(hh.Id);
        }
        if(idSet.size() > 0) {
            UtilityMethods.sendSAPIWrapper('FPIHousehold', 'update', idSet);
        }
    }

    global void finish(Database.BatchableContext BC) 
    {
        AutoRefreshBatch_Contacts b = new AutoRefreshBatch_Contacts(); 
        database.executebatch(b, 100); //Keeping batch size at 100
    }
}