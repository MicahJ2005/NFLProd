/**
 * Sends engagement data to SQS, for Tasteocracy 
 * 
 * Change History
 * ------------------------------------
 * 12.26.2023	Sophia Murphy (Demand Chain)
 * 				Initial Creation
 * ------------------------------------
 */
trigger TriggerFramework_EngagementTransaction on EngagementTransaction__c (after insert, after update, after delete, after undelete) {
    Map<String, Boolean> mapAPEXSettings = UtilityMethods.CODE_SETTINGS();
    if(mapAPEXSettings.get('enableEngagementTransactionTrigger')) {
        if(Trigger.isAfter) {
            UtilitySQS.processSQS('FPIEngagementTransaction', 'EngagementTransaction__c', Trigger.oldMap, Trigger.newMap);
        }
    }
}