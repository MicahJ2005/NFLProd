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
global class AutoRefreshBatch_Contacts implements Database.Batchable<sObject>
{
    public String query;
    
    global AutoRefreshBatch_Contacts() 
    {
    	this.query = 'SELECT Id FROM Contact WHERE LastModifiedDate >= LAST_N_DAYS:1' ;
        if(Test.isRunningTest())
        {
            this.query = 'SELECT Id FROM Contact WHERE LastModifiedDate >= LAST_N_DAYS:1 LIMIT 200' ;
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) 
    {
    	return Database.getQueryLocator(query);
    }

    /**global void execute(SchedulableContext sc) 
    {
      AutoRefreshBatch_Contacts b = new AutoRefreshBatch_Contacts(); 
      database.executebatch(b, 200);
    }*/

    global void execute(Database.BatchableContext BC, List<Contact> scope) 
    {
        Set<Id> idSet = new Set<Id>();
        for(Contact c : scope ) {
            idSet.add(c.Id);
        }
        if(idSet.size() > 0) {
            //UtilityMethods.sendSAPIWrapper('FPIRespondent', 'update', idSet);
            UtilitySQS.processSQS_withOperation('FPIRespondent', 'Contact', 'update', idSet, null);
        }
    }

    global void finish(Database.BatchableContext BC) 
    {
        AutoRefreshBatch_HouseholdContacts b = new AutoRefreshBatch_HouseholdContacts(); 
        //since we are running against Household Contacts and Contacts - make this batch 100.
        database.executebatch(b, 100);
    }
}