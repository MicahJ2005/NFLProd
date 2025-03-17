trigger TriggerFramework_Contact on Contact (after delete, after insert,  
after update, before delete, before insert, before update) {

/**
*   {Purpose}  �  Wrapper trigger for all functions on Contact - all business logic is to be placed in referenced
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
*   20131212    Andy Boettcher DCS      Created
*   20150823    Andy Boettcher DCS      Removed isUpdate from assignToRespondentAccount - Insert only per Lisa
*   20160321    Jason Flippen DCS       Added ContactLibrary.AfterUpdate() call
*   20210629    Sophia Murphy DCS       Added call to PushNotifications_Handler to merge contacts in Acoustic
*   20220707    Sophia Murphy DCS       Added enable/disable flag
*   20240214    Sophia Murphy DCS       Added calls to the EngagementBatch_Utility to create transactions
*   20240308    Sophia Murphy DCS       Removed code that is no longer needed
*   =============================================================================
*/

    // Create Map of APEX Trigger Settings
 
    Map<String, Boolean> mapAPEXSettings = UtilityMethods.CODE_SETTINGS();

    if(mapAPEXSettings.get('enableContactTrigger')) {

        if(trigger.isBefore) {
            
            if(mapAPEXSettings.get('assignToRespondentAccount')) {
                if(trigger.isInsert) {
                    ContactLibrary.assignToRespondentAccount(trigger.new);
                }
            }
            
            /** 03.08.20224 - Sophia Murphy (Demand Chain)
             * Commented out
             if(mapAPEXSettings.get('contactSoundexKey')) {
                if(trigger.isInsert || trigger.isUpdate) {
                    UtilityMethods.determineSoundexKey('LastNameSoundexKey__c', 'LastName');
                    UtilityMethods.determineSoundexKey('FirstNameSoundexKey__c', 'FirstName');
                }
            }
            */
            /** 03.08.20224 - Sophia Murphy (Demand Chain)
             * Commented out
            if(mapAPEXSettings.containsKey('updateZipCodeContactWork')) {
                if(mapAPEXSettings.get('updateZipCodeContactWork') && !UtilityMethods.bolTriggerRecurseFlag) {
                    if(trigger.isInsert || trigger.isUpdate) {
                        UtilityMethods.bolTriggerRecurseFlag = true;
                        UtilityMethods.determineZipZone(trigger.new, 'Work_Zip_Code__c', 'Work_Zone__c');
                        UtilityMethods.determineLocalTestingCenters(trigger.new, 'Work_Zip_Code__c', 
                            'Centers_5mi_Work__c', 'Centers_10mi_Work__c', 'Centers_15mi_Work__c');
                    }
                }
            }
            */
        }

        if(trigger.isAfter) {

            if(Trigger.isUpdate || Trigger.isInsert) {
                EngagementBatch_Utility.createReferralTransactions(Trigger.oldMap, Trigger.newMap);
                EngagementBatch_Utility.createProfileSurveyTransactions(Trigger.oldMap, Trigger.newMap);
            }

            if (Trigger.isUpdate) 
            {
                                                        // After Update
                ContactLibrary.afterUpdate(Trigger.new,
                                        Trigger.newMap,
                                        Trigger.old,
                                        Trigger.oldMap);

                
                //08.19.2022 - Sophia Murphy (Demand Chain)
                // Added check for isbatch, the Batch_ProfileAutoUpdate updates the Contact records and this was throwing an error
                if(!System.isBatch()) {
                    System.debug('DC: Calling PNH.MergeContactsInAcoustic');
                    PushNotifications_Handler.mergeContactsInAcoustic(Trigger.new);            
                }               
            }

            ///////////////////////////
            // Amazon SQS
            ///////////////////////////

            UtilitySQS.processSQS('FPIRespondent', 'Contact', Trigger.oldMap, Trigger.newMap);
            
            /** TEMP COMMENT OUT if(!UtilityMethods.bolPreventContactRollup) {

                String strSQSQueue = 'FPIRespondent';
                String strOperation = 'merge';
                
                // Send all normal records
                if(!UtilityMethods.bolPreventContactSQS) {
                    UtilityMethods.sendSAPITriggerWrapper(strSQSQueue);
                }

                if(trigger.isDelete) {
                    // Append DEV vs. PROD in the SQS Queue String
                    if(UtilityMethods.isSandbox()) {
                        strSQSQueue+= 'Dev';
                    } else {
                        strSQSQueue+= 'Prod';
                    }

                    // Specify Tags for Logging
                    List<String> lstTags = new List<String>();
                    lstTags.add('SFDC.SQS');
                    lstTags.add(strSQSQueue);
                    lstTags.add(strOperation);

                    String strJSONPayload = UtilityMethods.prepareSAPICalloutPayload(strSQSQueue, strOperation, trigger.old);
                    UtilityMethods.processOutboundSQSFuture(strSQSQueue, strJSONPayload, lstTags, trigger.oldMap.keySet());
                }
            }
            */
            
            
        }

    }

}