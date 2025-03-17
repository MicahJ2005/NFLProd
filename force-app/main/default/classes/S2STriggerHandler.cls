public class S2STriggerHandler {
/**
*   {Purpose}   - Trigger Handler for S2S REST-Based "ETL-Lite"
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
*   =============================================================================
*/
    public static void doNothing() {}
/** commented out - no longer needed
     * 
     * @future(callout=true)
    public static void handleRecords(String connectionOrg, String apiName,String recordStr){
        List<sObject> records = (List<sObject>)JSON.deserialize(recordStr,List<sObject>.class);
		S2S_Object__mdt setting = [SELECT 
                                        Id, 
                                        External_Id_Name__c,
                                        Ready_Field__c,
                                        API_Name__c,
                                        (SELECT 
                                            Source_Field__c, 
                                            Target_Field__c, 
                                            IsLiteral__c,
                                            Literal_Value__c
                                        FROM 
                                            S2S_Fields__r) 
                                    FROM S2S_Object__mdt 
                                    WHERE QualifiedApiName = :apiName
                                    LIMIT 1
        ];

        List<sObject> sObjects = new List<sObject>();
        Map<String, String> mapTranslation = new Map<String, String>();
        Set<String> setFieldsToIgnore = new Set<String>();

        Schema.SObjectType objSObjectResult = Schema.getGlobalDescribe().get(setting.API_Name__c);
        Map<String, Schema.SObjectField> mapFields = objSObjectResult.getDescribe().fields.getMap();
        Map<String, Schema.DescribeFieldResult> mapFieldResult = new Map<String, Schema.DescribeFieldResult>();

        // Do all GetDescribes up front
        for(S2S_Field__mdt objField : setting.S2S_Fields__r){
            mapFieldResult.put(objField.Source_Field__c, mapFields.get(objField.Source_Field__c).getDescribe());
        }

        // Start Processing Records
        for(sObject record : records){

            setFieldsToIgnore = new Set<String>();

            sObject obj = (sObject)Type.forName(setting.API_Name__c).newInstance();

            // For Opportunity, because we have the weird two-way going, handle how it was sourced...
            if(setting.API_Name__c == 'Opportunity') {
                if(record.get('CovanceCommercialId__c') == null) {
                    mapFieldResult.remove('CovanceCommercialId__c');
                    setFieldsToIgnore.add('CovanceCommercialId__c');
                } else {
                    mapFieldResult.remove('Id');
                    setFieldsToIgnore.add('Id');
                }
            }

            // Handling Child Objects (MasterId cannot be reparented)
            if(setting.API_Name__c == 'OpportunityLineItem' || setting.API_Name__c == 'OpportunityContactRole') {
                obj = record;
            }

            if((Boolean)record.get(setting.Ready_Field__c)) {

                for(S2S_Field__mdt objField : setting.S2S_Fields__r){

                    System.Debug('PROCESSING ' + objField.Source_Field__c);

                    mapTranslation.put(objField.Source_Field__c, objField.Target_Field__c);

                    if(!setFieldsToIgnore.contains(objField.Source_Field__c)) {
                        if(mapFieldResult.get(objField.Source_Field__c).isUpdateable() || objField.Source_Field__c == 'Id') {
                            if(objField.isLiteral__c) {
                                obj.put(objField.Source_Field__c, objField.Literal_Value__c);
                            } else {
                                obj.put(objField.Source_Field__c,record.get(objField.Source_Field__c));
                            }

                            System.Debug(obj);
                        }
                    }

                }

                sObjects.add(obj);
            }
        }
        
        System.Debug('S2STriggerHandler.handleRecords - sObject List = ' + JSON.serialize(sObjects));

        if(!sObjects.isEmpty()) {
            S2SRESTfulService.authAndUpsert(connectionOrg,apiName,sObjects, mapTranslation);
        }
    }
    */
}