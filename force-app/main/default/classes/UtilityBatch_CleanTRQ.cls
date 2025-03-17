global class UtilityBatch_CleanTRQ implements Database.Batchable<sObject> {
/**
*   {Purpose}  �  Will clean up TRQs based on a TRQ query passed in
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20141105  	Andy Boettcher DCS		Created
*   =============================================================================
*/
	public String strQuery {get;set;}

	///////////////////////////
	// Constructors
	///////////////////////////
	global UtilityBatch_CleanTRQ() { }
	
	///////////////////////////
	// Action Methods
	///////////////////////////
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(strQuery);
	}

	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		UtilityMethods.bolPreventTRQSQS = true;
		UtilityMethods.bolPreventTRSQS = true;
		delete scope;
		UtilityMethods.bolPreventTRQSQS = false;
		UtilityMethods.bolPreventTRSQS = false;
	}

	global void finish(Database.BatchableContext BC) {
		// Intentionally Empty
	}
}