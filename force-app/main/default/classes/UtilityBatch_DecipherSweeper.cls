global class UtilityBatch_DecipherSweeper implements Database.Batchable<sObject>, Database.AllowsCallouts {
/**
*   {Purpose}  �  Queue up and pass Started TRs to the Beacon Sweeper
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20141103  	Andy Boettcher DCS		Created
*   =============================================================================
*/	
	String query;
	
	global UtilityBatch_DecipherSweeper() { 
		query = 'SELECT Id, Respondent__c, Master_Test__c, Master_Test__r.Screener_Link__c, DecipherSweepCount__c, ';
		query+= 'Master_Test__r.Pairs_Test__c, Master_Test__r.Pairs_Screener_Link__c, Respondent__r.Age__c ';
		query+= 'FROM Test_Respondent__c ';
        query+= 'WHERE Master_Test__r.Last_Session_Start__c > TODAY '; 
        query+= 'AND Master_Test__r.Screener_Link__c != null ';
        query+= 'AND Respondent_Status__c = \'Started\'' ; 
        // query+= 'AND TRQ_Count__c = 0 '; REMOVED BECAUSE OF TRQ PRE-SEEDING FROM 2015May
        query+= 'AND (DecipherSweepCount__c = null OR DecipherSweepCount__c < 3) ';
        query+= 'ORDER BY DecipherSweepCount__c DESC ';
        query+= 'LIMIT 500';
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> lstScope) {
	
   		List<Utility_Decipher.hClsTargetTR> lstTargets = new List<Utility_Decipher.hClsTargetTR>();

   		// Prepare for Sweeper
		for(Test_Respondent__c tr : (List<Test_Respondent__c>)lstScope) {

			Double dblSweepCount = tr.DecipherSweepCount__c;
   			if(dblSweepCount == null) { dblSweepCount = 0; }
   			dblSweepCount++;
   			tr.DecipherSweepCount__c = dblSweepCount;

		    lstTargets.add(new Utility_Decipher.hClsTargetTR(tr, tr.Master_Test__r));
		}

		// Fire sweeper!
		Utility_Decipher.downloadIncompleteResults(lstTargets);

		// Update TR Try Counts
		UtilityMethods.bolPreventTRSQS = true;
   		update lstScope;
   		UtilityMethods.bolPreventTRSQS = false;

	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}