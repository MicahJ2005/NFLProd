/**
 * Sends poll data to SQS, so Tasteocracy can present polls
 * on the mobile app
 * 
 * Change History
 * ------------------------------------
 * 05.09.2019	Sophia Murphy (Demand Chain)
 * 				Initial Creation
 * ------------------------------------
 */
trigger TriggerFramework_PollHeader on Poll_Header__c (after insert, after update, after delete, after undelete) {
    if(Trigger.isAfter) {
        UtilityMethods.sendSAPITriggerWrapper('FPIPollHeader'); 
    }
}