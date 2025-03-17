trigger TriggerFramework_Account on Account (after delete, after insert, after update, 
before delete, before insert, before update) {
/**
*   {Purpose}  �  Wrapper trigger for all functions on Attribute_Master__c - all business logic is to be placed in referenced
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
*   20140601    Andy Boettcher DCS      Created
*   =============================================================================
*/

    // Create Map of APEX Trigger Settings
    Map<String, Boolean> mapAPEXSettings = UtilityMethods.CODE_SETTINGS();

    /**if(trigger.isBefore) {
        
        if(mapAPEXSettings.containsKey('updateZipCodeAccount')) {
            if(mapAPEXSettings.get('updateZipCodeAccount') && !UtilityMethods.bolTriggerRecurseFlag) {
                if(trigger.isInsert || trigger.isUpdate) {
                    UtilityMethods.bolTriggerRecurseFlag = true;
                    UtilityMethods.determineZipZone(trigger.new, 'BillingPostalCode', 'Zone__c');
                }
            }
        }
    }*/

    if(trigger.isAfter) {

        ///////////////////////////
        // Amazon SQS
        ///////////////////////////
        UtilityMethods.sendSAPITriggerWrapper('FPIAccountFundOrg');
        
    }

}