@RestResource(urlMapping='/S2S/*')
global class S2SService {
/**
*   {Purpose}   - Main REST POST Service for S2S REST-Based "ETL-Lite"
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 952.223.5604               
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name                    Description
*   20171226    Andy Boettcher DCS      Created
*   20180309    Andy Boettcher DCS      Added split of UPDATE and UPSERT to support Id vs. External Id (stupid Salesforce!)
*   =============================================================================
*/
    
    @HttpPost  
    global static UpsertResponse upsertRecords(String records, String apiName, String externalId, Map<String, String> translationMap) {
        UpsertResponse response = new UpsertResponse();
        try{

            // Set initial upsert result container
            Database.UpsertResult[] results = null;
            Database.SaveResult[] resultsUpdate = null;
           
            // Get all fields for passed object/apiName
            Schema.DescribeSObjectResult describeResult = 
                Schema.describeSObjects(new List<String>{apiName}).get(0);
            Map<String,Schema.SObjectField> fieldMap = describeResult.fields.getMap();
            Schema.SObjectField externalIdField = fieldMap.get(externalId);

            // Perform "ETL-LITE" to move field names from source to target
            List<sObject> lstRecords = S2SService.translateRecords(records, translationMap);

            System.debug(JSON.serialize(lstRecords));

            // Accounts
            //if(apiName == 'Account') {
            //    List<Account> accounts = new List<Account>();
            //    for(sObject objGeneric : (List<Account>)lstRecords) {
            //        accounts.add((Account)objGeneric);
            //    }
            //    results = Database.upsert(accounts,externalIdField,false);
            //}
            //

            // Leads
            if(apiName == 'Lead') {
                List<Lead> leads = new List<Lead>();
                for(sObject objGeneric : (List<Lead>)lstRecords) {
                    leads.add((Lead)objGeneric);
                }
                results = Database.upsert(leads,externalIdField,false);
            }
            
            // Opportunities
            if(apiName == 'Opportunity') {
                List<Opportunity> opportunitiesUpdate = new List<Opportunity>();
                List<Opportunity> opportunitiesUpsert = new List<Opportunity>();
                for(sObject objGeneric : (List<Opportunity>)lstRecords) {
                    Opportunity objOpp = (Opportunity)objGeneric;
                    if(objOpp.Id == null) {
                        opportunitiesUpsert.add(objOpp);    
                    } else {
                        opportunitiesUpdate.add(objOpp); 
                    }
                    
                }
                
                if(!opportunitiesUpsert.isEmpty()) {
                    results = Database.upsert(opportunitiesUpsert,externalIdField,false);    
                }
                if(!opportunitiesUpdate.isEmpty()) {
                    resultsUpdate = Database.update(opportunitiesUpdate);    
                }
                
            }

            if(apiName == 'OpportunityLineItem') {
                List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
                for(sObject objGeneric : (List<OpportunityLineItem>)lstRecords) {
                    olis.add((OpportunityLineItem)objGeneric);
                }
                results = Database.upsert(olis,externalIdField,false);
            }

            // Process any DML errors
            response.recordErrors = new List<RecordError>();
            /**  20220707   Sophia Murphy DCS - Commented out, no longer needed
            List<Automation_Audit_Log__c> lstAudit = new List<Automation_Audit_Log__c>();
            */
            if(resultsUpdate != null) {
                for(Database.SaveResult result : resultsUpdate) {
                    // Complete Audit Trail
                    /**  20220707   Sophia Murphy DCS - Commented out, no longer needed
                    Automation_Audit_Log__c objAudit = new Automation_Audit_Log__c();
                    objAudit.Apex_Source__c = 'S2SService.cls';
                    objAudit.Apex_Method__c = 'upsertRecords';
                    objAudit.Automation_Type__c = 'Apex';
                    objAudit.Details__c = JSON.serialize(result.getErrors()) + '\r\n' + JSON.serialize(lstRecords);
                    objAudit.IsSuccess__c = result.isSuccess();
                    objAudit.RecordId__c = result.getId();
                    lstAudit.add(objAudit);
                    */
                    
                    // Set REST Response if FAILURE
                    if(!result.isSuccess()){
                        RestContext.response.statusCode = 500;
                        Database.Error err = result.getErrors().get(0);
                        response.recordErrors.add(new RecordError(result.getId(),err.getStatusCode() + ': ' + err.getMessage()));
                    }
                }
            }
            
            if(results != null) {
                for(Database.UpsertResult result : results){
    
                    // Complete Audit Trail
                    /**  20220707   Sophia Murphy DCS - Commented out, no longer needed
                    Automation_Audit_Log__c objAudit = new Automation_Audit_Log__c();
                    objAudit.Apex_Source__c = 'S2SService.cls';
                    objAudit.Apex_Method__c = 'upsertRecords';
                    objAudit.Automation_Type__c = 'Apex';
                    objAudit.Details__c = JSON.serialize(result.getErrors()) + '\r\n' + JSON.serialize(lstRecords);
                    objAudit.IsSuccess__c = result.isSuccess();
                    objAudit.RecordId__c = result.getId();
                    lstAudit.add(objAudit);
                    */
    
                    // Set REST Response if FAILURE
                    if(!result.isSuccess()){
                        RestContext.response.statusCode = 500;
                        Database.Error err = result.getErrors().get(0);
                        response.recordErrors.add(new RecordError(result.getId(),err.getStatusCode() + ': ' + err.getMessage()));
                    }
                }
            }

            // Commit Audit
            /**  20220707   Sophia Murphy DCS - Commented out, no longer needed
            if(!lstAudit.isEmpty()) {
                insert lstAudit;
            }
            */


        } catch(Exception e){
            RestContext.response.statusCode = 500;
            response.error = e.getMessage() + ';' + e.getStackTraceString();
        }

        // Finalize and return to calling system
        return response;
    }

    public static List<sObject> translateRecords(String recordJSON, Map<String, String> translationMap) {

        // Find/Replace in recordJSON
        for(String strSourceField : translationMap.keySet()) {
            String strTargetField = translationMap.get(strSourceField);

            if(strSourceField != strTargetField) {
                recordJSON = recordJSON.replace('\"' + strSourceField + '\"', '\"' + strTargetField + '\"');
            }
        }

        List<sObject> lstRecords = (List<sObject>)JSON.deserialize(recordJSON, List<sObject>.class);
        List<sObject> lstScrubbedRecords = new List<sObject>();

        // Clear out any NULL fields
        for(sObject obj : lstRecords) {

            Map<String, Object> objTranslated = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj));

            for(String strFieldName : translationMap.values()) {
                if(obj.get(strFieldName) == null) {
                    objTranslated.remove(strFieldName);
                }
            }

            sObject objFinalTranslated = (sObject) JSON.deserialize(JSON.serialize(objTranslated), sObject.class);
            lstScrubbedRecords.add(objFinalTranslated);
            
        }
        return lstScrubbedRecords;       

    }       
    
    global class UpsertResponse{
        global List<RecordError> recordErrors {get; set;}
        global String state {get; set;}
        global String error {get; set;}
    }
       
    global class RecordError{
        global String recordId {get; set;}
        global String error {get; set;}
       
        global RecordError(){}
       
        global RecordError(String recordId,String error){
            this.recordId = recordId;
            this.error = error;
        }
    }
}