trigger TriggerFramework_TRQ on Test_Respondent_Quota__c (after insert, after update, after delete, after undelete) {
/**
*   {Purpose}  �  Wrapper trigger for all functions on Test_Respondent_Quota__c - all business logic is to be placed in referenced
*        classes and only routing logic is to be created here.
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name                  Description
*   20140703    Andy Boettcher DCS    Created
*   20160430    Andy Boettcher DCS    Added support for computeQuotaReportingMetrics
*                                     Rollup Helper cannot handle +50,000 rows
*   20220707    Sophia Murphy DCS       Added enable/disable flag
*   =============================================================================
*/

    // Create Map of APEX Trigger Settings
    Map<String, Boolean> mapAPEXSettings = UtilityMethods.CODE_SETTINGS();
    Set<Id> setTRIds = new Set<Id>();
  
    if(mapAPEXSettings.get('enableTRQTrigger')) {
      if(trigger.isAfter) {

        // Send Data to Amazon SQS for TRQ
        UtilityMethods.sendSAPITriggerWrapper('FPITestRespondentQuota');

        // Handle trigger scope - put in central List
        String strOperation = '';
        List<Test_Respondent_Quota__c> lstTRQs;
        if(trigger.isInsert || trigger.isUndelete) { strOperation = 'insert'; lstTRQs = trigger.new; }
        if(trigger.isUpdate) { strOperation = 'update'; lstTRQs = trigger.new; }
        if(trigger.isDelete) { strOperation = 'delete'; lstTRQs = trigger.old; }

        System.Debug('TriggerFramework_TRQ.EXECUTE - Running ' + lstTRQs.size() + ' TRQs');

        // Handle Trigger Chunking when TRQ set is > 200 records
        for(Test_Respondent_Quota__c trq : lstTRQs) {

          // Add to Scope List
          setTRIds.add(trq.Test_Respondent__c);

          // Add to Batch List
          if(!UtilityMethods.setTRQTriggerChunkingIds.contains(trq.Test_Respondent__c)) {
            UtilityMethods.setTRQTriggerChunkingIds.add(trq.Test_Respondent__c);
          }
        }

        // Inserts - we don't need to run metrics
        if(trigger.isInsert) {
          if(setTRIds.size() > 0) {
            UtilityMethods.sendSAPIWrapper('FPITestRespondent', strOperation, setTRIds);
          }
        }

        // Updates and Deletes, run metrics!
        if(trigger.isUpdate || trigger.isDelete) {

          //09.27.2021 - Sophia Murphy (Demand Chain)
          //            Need to add in check against limits to make sure we don't go over them.
          if(Limits.getQueries() < 90) {
            Integer intTRQCount = [SELECT COUNT() FROM Test_Respondent_Quota__c WHERE Test_Respondent__c IN :setTRIds];

            UtilityMethods.intTRQTriggerRecordCount+= lstTRQs.size();

            // If this is the last trigger in the batch
            System.Debug('CHECKING TO SEE IF THIS IS THE LAST TRIGGER BATCH: ' + intTRQCount + ' / ' + UtilityMethods.intTRQTriggerRecordCount);
            if(intTRQCount == UtilityMethods.intTRQTriggerRecordCount || intTRQCount < 200) {
              System.Debug('PROCESS LAST BATCH IN TRIGGER - METRICS AND SQS');

              if(!System.isFuture() && !System.isBatch() && !UtilityMethods.setTRQTriggerChunkingIds.isEmpty()) {
                MasterTestLibrary.computeQuotaReportingMetrics(UtilityMethods.setTRQTriggerChunkingIds);
              }

              if(!UtilityMethods.setTRQTriggerChunkingIds.isEmpty()) {
                UtilityMethods.sendSAPIWrapper('FPITestRespondent', strOperation, UtilityMethods.setTRQTriggerChunkingIds);
              }
            }
          } //END: if(Limits.getQueries() < 90)
        } //END: if(trigger.isUpdate || trigger.isDelete)
      }
    }
}