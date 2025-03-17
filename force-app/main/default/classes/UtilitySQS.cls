/** Created to slowly replace some of the methods in UtilityMethods, in particular
 *  How data is sent to SQS/Amazon.
 * 
 *  As of March 2024 - this is only used for Contacts and Master Tests
 * 
 *   CHANGE  HISTORY
 *   =============================================================================
 *   Date        Name / Description
 *   03/08/2024  Sophia Murphy (Demand Chain)
 *               Initial creation
*/
global with sharing class UtilitySQS {

    //If there are particular queries that need additional filtering,
    //aside from the Id IN :setIds; put those here.  
    // with the SQS Queue name as the Map's key
    public static Map<String, String> SQS_ADDLWHERES() {
        Map<String, String> mapWhere = new Map<String, String>();

        mapWhere.put('FPIRespondent', ' AND RecordTypeId IN (\'012U00000009efc\',\'012U00000009efd\')');
        //These are used quite yet
        //mapWhere.put('FPIAccountFundOrg',' AND RecordTypeId IN (\'012U00000009fdB\')');
        //mapWhere.put('FPITestRespondent',' AND Respondent__c != null');
        //mapWhere.put('FPIOpenMasterTests', ' AND IsAvailableToRecruit__c = TRUE');
        //mapWhere.put('FPIOpenSessions', ' AND IsAvailableToRecruit__c = TRUE');
        //mapWhere.put('FPIOpenQuotas', ' AND IsOpen__c = TRUE');
       
        return mapWhere;
    }

    public static void processSQS(String strSQSQueue, String objectName, Map<Id, sObject> oldMap, Map<Id, sObject> newMap) {

        // Determine Scope and if there are records
        String strOperation;
        Set<Id> setIds = new Set<Id>();
        if(trigger.isExecuting) {
            if(trigger.isInsert || trigger.isUndelete) { 
                strOperation = 'insert'; 
                setIds = trigger.newMap.keyset(); 
            }
            if(trigger.isUpdate) { 
                strOperation = 'update'; 
                setIds = trigger.newMap.keyset(); 
            }
            if(trigger.isDelete) { 
                strOperation = 'delete'; 
                setIds = trigger.oldMap.keyset(); 
            }
        } else {
            // If no Ids are passed, just end processing
            if(setIds == null) {
                System.Debug('NULL SIZE SET FOR SQS ' + strSQSQueue + ' - ' + strOperation + ' PUSH, TERMINATING');
                return;
            }
        }
        System.debug('DC: strOperation: ' + strOperation);
        System.debug('DC: setIds: ' + setIds);

        //Get the list of fields we are dealing with
        //NOTE: LastModifiedDate SHOULD NOT BE IN THIS FIELDSET; else EVERY record will end up coming over!
        List<String> selectFields = UtilityMethods.fieldSetFields(objectName, 'SQS_Queue');
        System.debug('DC: selectFields: ' + selectFields);

        //Determine which records have valid changes that mean they should be sent to Tasteocracy.
        Set<Id> recordsWithValidChanges;
        if(strOperation == 'update') {
            recordsWithValidChanges = validChanges(objectName, selectFields, oldMap, newMap);
        } else {
            //If it's an insert or a delete - send it over
            recordsWithValidChanges = setIds;
        } 
        System.debug('DC: recordsWithValidChanges: ' + recordsWithValidChanges);
        
        //If there aren't any records we care about - then exit
        if(recordsWithValidChanges.size() <= 0) {
            return;
        }
        processSQS_withOperation(strSQSQueue, objectName, strOperation, recordsWithValidChanges, selectFields);
    }

    public static void processSQS_withOperation(String strSQSQueue, String objectName, String strOperation, Set<Id> recordIds, List<String> selectFields) {

        // Append DEV vs. PROD in the SQS Queue String
        if(UtilityMethods.isSandbox()) {
            strSQSQueue+= 'Dev';
        } else {
            strSQSQueue+= 'Prod';
        }

        // Protect against limit breach on DML and SOQL
        if(limits.getQueries() >= limits.getLimitQueries()) {
            return;
        }

        // Query and return Map
        Map<Id, sObject> mapRecords;
        Map<String, String> mapWheres = UtilitySQS.SQS_ADDLWHERES();
        String extraWhere = mapWheres.get(strSQSQueue);

        //Next build out our query
        if(selectFields == null) {
            selectFields = UtilityMethods.fieldSetFields(objectName, 'SQS_Queue');
        }

        String strQuery = 'SELECT ' + String.join(selectFields, ', ') + ', LastModifiedDate FROM ' + objectName;
        strQuery += ' WHERE Id IN :recordIds ';
        if(extraWhere != null) {
            strQuery += extraWhere;
        }
        //TODO: Some of the queries may need extra WHERE statements added
        Map<String, Object> queryBinds = new Map<String, Object>{'recordIds' => recordIds};

        if(trigger.isExecuting && trigger.isDelete) {
            //If it's a delete, we can't query for the records - so we will just put in the info we know from the oldMap/trigger
            mapRecords = new Map<Id, sObject>();
            for(sObject so : trigger.old) {
                mapRecords.put((Id)so.get('Id'), so);
            }
        } else {
            //mapRecords = new Map<Id, sObject>(Database.query(strQuery));
            mapRecords = new Map<Id, sObject>(Database.queryWithBinds(strQuery, queryBinds, AccessLevel.USER_MODE));
        }
    
        // If no Results are passed, just end processing
        //Could be that we have extra WHERE criteria that is further filtering out records - in those cases; just exit
        // if we have nothing to send.
        if(mapRecords.size() == 0) {
            System.Debug('ZERO SIZE RECORDS FOR SQS ' + strSQSQueue + ' - ' + strOperation + ' PUSH, TERMINATING');
            return;
        }
    
        // Specify Tags for Logging
        List<String> lstTags = new List<String>();
        lstTags.add('SFDC.SQS');
        lstTags.add(strSQSQueue);
        lstTags.add(strOperation);

        System.Debug('CALLOUTS = ' + Limits.getFutureCalls() + '/' + Limits.getLimitFutureCalls());

        // Build payload object
        String strJSONPayload = UtilityMethods.prepareSAPICalloutPayload(strSQSQueue, strOperation, mapRecords.values());
        System.Debug('FUTURE = ' + System.isFuture());
        System.Debug('BATCH = ' + System.isBatch());
        System.Debug('TRIGGER = ' + trigger.isExecuting);
    
        if(System.isBatch() && trigger.isExecuting) {
            System.Debug('Cannot send callouts from a Trigger invoked via Batch!');
            return;
        }
    
        //07/16/2020 - added AutoRefreshBatch_xx methods; need to send those via future
        if(System.isFuture() == false && System.isBatch() == true && trigger.isExecuting == false) {
            UtilityMethods.LOG_MESSAGE('UtilityMethods.sendSAPIWrapper', 'Sending Asynchronous SQS Call');
            if(limits.getFutureCalls() < limits.getLimitFutureCalls()) {
                UtilityMethods.processOutboundSQSFuture(strSQSQueue, strJSONPayload, lstTags, mapRecords.keySet());
            }
        }
        else if((System.isFuture() || System.isBatch()) || !trigger.isExecuting) {
            UtilityMethods.LOG_MESSAGE('UtilityMethods.sendSAPIWrapper', 'Sending Synchronous SQS Call');
            UtilityMethods.processOutboundSQS(strSQSQueue, strJSONPayload, lstTags, mapRecords.keySet());
        } else {
            UtilityMethods.LOG_MESSAGE('UtilityMethods.sendSAPIWrapper', 'Sending Asynchronous SQS Call');
            if(limits.getFutureCalls() < limits.getLimitFutureCalls()) {
                UtilityMethods.processOutboundSQSFuture(strSQSQueue, strJSONPayload, lstTags, mapRecords.keySet());
            }
        }
    } //END: processSQS

    /** 
     *  accepts an object name, trigger new and old
     *  Looks up the SQS_Queue field set on the object; if a field in that fieldset has changed
     *  then this returns TRUE
     */
    public static Set<Id> validChanges(String objectName, List<String> selectFields, Map<Id, sObject> oldMap, Map<Id, sObject> newMap) {
        //First get all the fields in the field set
        Set<Id> returnSet = new Set<Id>();
       
        for(Id recordId : oldMap.keySet()) {
            sObject oldRecord = oldMap.get(recordId);
            sObject newRecord = newMap.get(recordId);
            Boolean doAdd = false;

            for(String fieldName : selectFields) {
                if(oldRecord.get(fieldName) != newRecord.get(fieldName)) {
                    doAdd = true;
                    break;
                }
            }

            if(doAdd) {
                returnSet.add(recordId);
            }
        }
        return returnSet;
    }

}