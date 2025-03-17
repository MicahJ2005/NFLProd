trigger TriggerFramework_SessionQuota on Session_Quota__c (after delete, after insert, after undelete, after update) {

/**
*   {Purpose}  �  Wrapper trigger for all functions on Session Quota - all business logic is to be placed in referenced
*               classes and only routing logic is to be created here.
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name                    Description
*   20140926    Andy Boettcher DCS      Created
*   =============================================================================
*/

    // Create Map of APEX Trigger Settings
    //Map<String, Boolean> mapAPEXSettings = UtilityMethods.CODE_SETTINGS();

    if(trigger.isAfter) {

        ///////////////////////////
        // Amazon SQS
        ///////////////////////////
        if(!UtilityMethods.bolPreventSQSQS) { 
        	UtilityMethods.sendSAPITriggerWrapper('FPIQuota');
        }
        
    }
}