/******************************************************************************
 * This can be scheduled, or run manually. 
 *		MTRefreshStatsBatch batchClass = new MTRefreshStatsBatch(); 
 *		Database.ExecuteBatch(batchClass, 10);
 *
 *  MTRefreshStatsBatch
 *		Query for all active Master Test records and send them to the
 *      HostTool method to run the calculations.
 * 
 * @Author:			Sophia Murphy(Demand Chain)
 * @Date: 			05.08.2020
 *
 * @Updates
 * 						
 */

global class MTRefreshStatsBatch implements Database.Batchable<sObject> , Schedulable, Database.Stateful   
{
	
	public String query;
    
    global MTRefreshStatsBatch() 
    {
    	this.query = 'SELECT Id FROM Master_Test__c  WHERE Master_Test_Status_1__c = \'Approved\' ';
        if(Test.isRunningTest())
        {
            this.query += ' LIMIT 200' ;
        }

    	System.debug('DC: query ' + query ) ;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) 
    {
    	return Database.getQueryLocator(query);
    }
    
    global void execute(SchedulableContext sc) 
    {
        MTRefreshStatsBatch b = new MTRefreshStatsBatch(); 
        database.executebatch(b, 20);
    }

    global void execute(Database.BatchableContext BC, List<Master_Test__c> scope) 
    {
    	
    	for(Master_Test__c mt : scope)
    	{
            //Send the MT id over to the MTRefreshStatsController.
            MTRefreshStatsController.updateMT(mt.Id);
    	}
    	
    }

    global void finish(Database.BatchableContext BC) 
    {
    	
    }
}