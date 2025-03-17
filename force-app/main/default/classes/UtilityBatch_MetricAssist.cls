global class UtilityBatch_MetricAssist implements Database.Batchable<sObject>, Database.AllowsCallouts {
	
	String query = 'SELECT Id FROM Master_Test__c WHERE IsAvailableToRecruit__c = TRUE';
	global List<UtilityMethods.hClsMetricAssist> lstPayloads = new List<UtilityMethods.hClsMetricAssist>();
	
	global UtilityBatch_MetricAssist() {
		System.Debug('******* STARTING PAYLOAD ASSIST **********');
		System.Debug(lstPayloads);
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {

   		for(UtilityMethods.hClsMetricAssist clsAssist : lstPayloads) {
   			System.Debug('PUSHING to SQS - ' + clsAssist.strSQSQueue + ' - ' + clsAssist.strJSONPayload);
   			UtilityMethods.sendSAPICalloutToAmazon(clsAssist.strSQSQueue, clsAssist.strJSONPayload);

			// Specify Tags for Logging
	        List<String> lstTags = new List<String>();
	        lstTags.add('SFDC.SQS');
	        lstTags.add(clsAssist.strSQSQueue);
	        lstTags.add('update');

	        UtilityMethods.sendBulkLogglyMessageFull(lstTags, null, clsAssist.strJSONPayload);

   		}
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}