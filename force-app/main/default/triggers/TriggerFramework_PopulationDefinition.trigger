trigger TriggerFramework_PopulationDefinition on Population_Definition__c (after delete, after insert, after undelete, after update) {

/**
*   {Purpose}  �  Wrapper trigger for all functions on Population Definition - all business logic is to be placed in referenced
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
*   20200122    Peter Moore DCS      Created
*   =============================================================================
*/

    if(trigger.isAfter) {

        ///////////////////////////
        // Amazon SQS
        ///////////////////////////
        if(!UtilityMethods.bolPreventSQSQS) { 
        	UtilityMethods.sendSAPITriggerWrapper('TasteocracyPopulationDefinitionTopic');
        }
        
    }
}