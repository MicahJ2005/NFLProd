trigger TriggerFramework_Household on Household__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {

/**
*   {Purpose}  �  Wrapper trigger for all functions on Household - all business logic is to be placed in referenced
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
*   20140520    Andy Boettcher DCS      Created
*   20160321    Jason Flippen DCS       Added HouseholdLibrary.AfterUpdate() call
*   20220707    Sophia Murphy DCS       Added enable/disable flag
*   =============================================================================
*/

    // Create Map of APEX Trigger Settings
    Map<String, Boolean> mapAPEXSettings = UtilityMethods.CODE_SETTINGS();

    System.Debug('********************** Household Trigger Start Queries = ' + Limits.getQueries());

    if(mapAPEXSettings.get('enableHouseholdTrigger')) {
        if(trigger.isBefore) {
            
            //if(mapAPEXSettings.get('updateZipCodeHousehold') && !UtilityMethods.bolTriggerRecurseFlag) {
            //    if(trigger.isInsert || trigger.isUpdate) {
            //        UtilityMethods.bolTriggerRecurseFlag = true;
            //        UtilityMethods.determineZipZone(trigger.new, 'MailingPostalCode__c', 'Zone__c');
            //        UtilityMethods.determineLocalTestingCenters(trigger.new, 'MailingPostalCode__c', 
            //                'Centers_5mi__c', 'Centers_10mi__c', 'Centers_15mi__c');
            //    }
            //}
        }

        if(trigger.isAfter) {

            if (Trigger.isUpdate) {
                HouseholdLibrary.afterUpdate(Trigger.new, Trigger.newMap, Trigger.old, Trigger.oldMap);
                //08.19.2022 - Sophia Murphy (Demand Chain)
                // Added check for isbatch, the Batch_ProfileAutoUpdate updates the Household records and this was throwing an error
                if(!System.isBatch()) {
                    HouseholdLibrary.checkHeadOfHousehold(trigger.newMap.keyset());
                }
            }

            ///////////////////////////
            // Amazon SQS
            ///////////////////////////
            if(!UtilityMethods.bolPreventHouseholdSQS) {
                UtilityMethods.sendSAPITriggerWrapper('FPIHousehold');

                String strSQSQueueSuffix = '';
                // Append DEV vs. PROD in the SQS Queue String
                if(UtilityMethods.isSandbox()) {
                    strSQSQueueSuffix = 'Dev';
                } else {
                    strSQSQueueSuffix = 'Prod';
                }

                if(trigger.isDelete) {
                    Map<Id, Household_Contact__c> mapHContacts = new Map<Id, Household_Contact__c>([
                        SELECT Id FROM Household_Contact__c WHERE Household__c IN :trigger.oldMap.keyset()
                    ]);

                    String strJSONPayload = UtilityMethods.prepareSAPICalloutPayload('FPIHouseholdContact' + strSQSQueueSuffix, 'delete', mapHContacts.values());
                    UtilityMethods.sendSAPICalloutToAmazon('FPIHouseholdContact' + strSQSQueueSuffix, strJSONPayload);
                }
            }
        }
    }
    System.Debug('********************** Household Trigger End Queries = ' + Limits.getQueries());
}