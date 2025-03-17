global with sharing class UtilityGlobalMethods {
/**
*   {Purpose}  �  Global class for all methods called from JS buttons or other SOAP methods
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20141125  	Andy Boettcher DCS		Created
*   =============================================================================
*/	
	
	///////////////////////////
	// Action Methods
	///////////////////////////
    WebService static sObject cloneObject(String strTitleField, Id idSourceRecord) {

        Map<String, String> mapObjects = UtilityMethods.OBJECT_MAP();
        String strObjectPrefix = string.valueOf(idSourceRecord).substring(0,3);
        String strObjectName = mapObjects.get(strObjectPrefix);

        // Gather List of all Createable Case Fields
        String strFields = '';
        SObjectType sot = Schema.getGlobalDescribe().get(strObjectName);
        List<Schema.SObjectField> lstFields = sot.getDescribe().fields.getMap().values();
        for(Schema.Sobjectfield so : lstFields) {
            Schema.DescribeFieldResult dfr = so.getDescribe();
            if (dfr.isCreateable()) {
                strFields += dfr.getName() + ',';
            }
        }

        // Create Source Case Object
        if (strFields.endsWith(',')) {strFields = strFields.substring(0,strFields.lastIndexOf(',')); }
        String strQuery = 'SELECT ' + strFields + ' FROM ' + strObjectName + ' WHERE Id = :idSourceRecord';
        sObject cSource = Database.query(strQuery);

        // Clone and Insert Clone
        sObject cTarget = cSource.clone();
        cTarget.put(strTitleField, cTarget.get(strTitleField) + ' – Clone');
        insert cTarget;

        return cTarget;

    }
}