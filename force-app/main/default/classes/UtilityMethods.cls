global with sharing class UtilityMethods {

/**
*   {Purpose}  �  General Use Methods for all code
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
*   20190509    Sophia Murphy (Demand Chain)
*               Added queries for Poll Objects
*   20200124    Added queries for Population Definition
*   20210412    Sophia Murphy (Demand Chain)
*				Added respondentCheck to allowed webservice calls
*	20230524 	Sammy Zawahiri (Demand Chain)
*				Added confirmTesting Method to allow WS calls.
*   20240201    Sophia Murphy (Demand Chain)
*               Added respondentCashOut
*   20240308    Sophia Murphy (Demand Chain)
*               Added method to find all fields in a fieldset
*   =============================================================================
*/
    public static Boolean bolTriggerRecurseFlag = false;
    public static Boolean bolTriggerSignupFlag = false;
    public static Boolean bolPreventContactRollup = false;
    public static Boolean bolPreventTRQSQS = false;
    public static Boolean bolPreventContactSQS = false;
    public static Boolean bolPreventTRSQS = false;
    public static Boolean bolPreventSQSQS = false;
    public static Boolean bolPreventHouseholdSQS = false;
    public static Boolean bolPreventMetricRollup = false;

    public static Integer intTRQTriggerRecordCount = 0;
    public static Set<Id> setTRQTriggerChunkingIds = new Set<Id>();

    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    // UTILITY MAPS AND RETURN FUNCTIONS
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    public static Map<String, Boolean> CODE_SETTINGS() {
        Map<String, Boolean> mapAPEXSettings = new Map<String, Boolean>();
        for(FPI_APEXSettings__c ATS : FPI_APEXSettings__c.getall().values()) {
            mapAPEXSettings.put(ATS.Name, ATS.IsActive__c);
        }
        return mapAPEXSettings;
    }

    public static Map<String, String> APP_SETTINGS() {
        Map<String, String> mapAppSettings = new Map<String, String>();
        for(FPI_AppSettings__c ATS : FPI_AppSettings__c.getall().values()) {
            mapAppSettings.put(ATS.Name, ATS.Value__c);
        }
        return mapAppSettings;
    }

    public static UserPreference__c USER_PREFERENCES() {
        UserPreference__c csUP = UserPreference__c.getInstance(UserInfo.getUserId());
        return csUP;
    }

    public static Map<String, String> OBJECT_MAP() {
        Map<String, String> mapObjects = new Map<String, String>();
        for( Schema.SObjectType t : Schema.getGlobalDescribe().values() ){
            Schema.DescribeSObjectResult dsr = t.getDescribe();
            mapObjects.put(dsr.getKeyPrefix(), dsr.getName());
        }
        return mapObjects;
    }

    /**public static Map<String, String> ZIP_ZONES() {
        Map<String, String> mapZipZones = new Map<String, String>();
        for(Zip_Code_Zones__c ZCZ : Zip_Code_Zones__c.getall().values()) {
            mapZipZones.put(ZCZ.Name, ZCZ.Zone__c);
        }
        return mapZipZones;
    }*/

    public static Map<String, String> OBJECT_LABELMAP() {
        Map<String, String> mapObjects = new Map<String, String>();
        for( Schema.SObjectType t : Schema.getGlobalDescribe().values() ){
            Schema.DescribeSObjectResult dsr = t.getDescribe();

            String strPrefix = '';
            //if(dsr.getName().contains('ATC__')) {
            //    strPrefix = 'Avata ';
            //}

            mapObjects.put(dsr.getKeyPrefix(), strPrefix + dsr.getLabel());
        }
        return mapObjects;
    }

    public static Map<String, String> SQS_QUEUES() {
        Map<String, String> mapQueries = new Map<String, String>();

        mapQueries.put('FPIAccountFundOrg','SELECT Id, Status__c, CreatedDate, LastModifiedDate, Name FROM Account WHERE RecordTypeId IN (\'012U00000009fdB\')');
        mapQueries.put('FPIHouseholdContact','SELECT Id, CreatedDate, LastModifiedDate, Contact__c, Contact_Age__c, Contact_Gender__c, Household__c, Name, Status__c, Address__c FROM Household_Contact__c');
        mapQueries.put('FPIHousehold','SELECT Id, CreatedDate, LastModifiedDate, Name, International_Address__c, MailingCity__c, Head_of_Household__c, Home_Ownership__c, Household_Income__c, MailingPostalCode__c, MailingState__c, MailingStreet__c, MailingStreet2__c, MailingCountry__c, Type_of_Housing__c, Zone__c, Home_Ownership_Other__c FROM Household__c');
        mapQueries.put('FPIQuota','SELECT Id, CreatedDate, LastModifiedDate, Related_Session__c, Maximum_Respondents__c, Minimum_Respondents__c, Master_Quota__c, IsOpen__c, MQG__c, SQG__c, SQGManual__c, IsScheduleEnabled__c FROM Session_Quota__c');
        //03.20.2019 - Added RAF fields in
        //12.10.2019 - Added IsQCRecord__c
        
        /**String respondentQuery = 'SELECT CreatedDate, Next_Eligible_Test_date__c, LastModifiedDate, Job_Function__c, IsQCRecord__c, Status__c, Id, PID__c, PIN__c, PIN_Plain_Text__c, ';
        respondentQuery += 'LastName, FirstName, Name, Gender__c, Birthdate, Email, HomePhone, MobilePhone, Work_Phone__c, Text_Enabled__c, Ethnicity__c, Secondary_Ethnicity__c, ';
        respondentQuery += ' Completed_Education__c, Student_Status__c, Graduation_Date__c, Employment_Status__c, Work_Zip_Code__c, Work_Zone__c, Career_Industry__c, Test_Near_Work__c, ';
        respondentQuery += ' Family_Structure__c, Number_of_Children_Under_18__c, Number_of_Adults__c, Primary_Grocery_Shopper__c, Primary__c, Primary_Language__c, Shops_At__c, ';
        respondentQuery += ' Landline_Phone__c, IVRPhone__c, Food_Restrictions__c, Food_Allergies_c__c, Disabilities__c, Dietary_Choices__c, Comments_about_Career_Industry__c, ';
        respondentQuery += ' Assistance_Needed__c, Organization1__c, Referral_Method__c, Last_Qualitative_Participation__c, Last_Quantitative_Participation__c, Express_Testing_Respondent__c, ';
        respondentQuery += ' X3M_Panel__c, Product_Categories__c, Restriction_on_Qual_Participation__c, Donation_Amount_Per_Event__c, Make_Donation__c, Preferred_Phone__c, ';
        respondentQuery += ' Food_Allergies_Other__c, Shops_At_Other__c, Food_Restriction_Other__c, Dietary_Choices_Other__c, Flip_Status_Date__c, Newsletter_Opt_Out__c, Member_Since__c, ';
        respondentQuery += ' Age__c, FPITESTERS_Logins__c, Inactivation_Reason__c, Career_Industry_Other__c, Ethnicity_Other__c, Brand__c , Birthdate_Needs_Verification__c, Food_Lifestyle__c, ';
        respondentQuery += ' Shops_At_Type__c, Hispanic_Latino__c, Uses_Metro_Mobility__c, Focus_Group_Panel__c, ';
        respondentQuery += ' Communication_Preference_Email__c, Communication_Preference_None__c, Communication_Preference_Phone_Calls__c, Communication_Preference_Push_Notif__c, ';
        respondentQuery += '  Communication_Preference_SMS_Texting__c, Date_of_Updated_Comm_Preferences__c, Date_of_Updated_Opt_Outs__c, Kids_in_HH_Yes_No__c, ';
        respondentQuery += '  Opted_Out_Tasteocracy_Test_Advertising__c, Opted_Out_Tasteocracy_Updates__c, Opted_Out_Weekly_News_Letter__c, Preferred_Phone_Number__c, ';
        respondentQuery += '  Veg__c, W9_Business_Name__c ';
        respondentQuery += ' FROM Contact WHERE RecordTypeId IN (\'012U00000009efc\',\'012U00000009efd\')';
        mapQueries.put('FPIRespondent', respondentQuery);*/

        mapQueries.put('FPISession','SELECT CreatedDate, LastModifiedDate, RAF_Link__c, Session_End__c, Name, Session_Start__c, Related_Test__c, Id, Testing_Location__c, Testing_Location_Name__c, Testing_Location_Street__c, Testing_Location_City__c, Testing_Location_State__c, Testing_Location_Postal_Code__c, Research_Type__c, IsAvailableToRecruit__c, Linked_Session__c, Check_Amount__c, IsArticulationNeeded__c, Questionnaire_Link__c, Questionnaire_Link_Description__c, Moderator_Link__c, Moderator_Link_Description__c, Test_Type__c, Opportunity_Number__c, Brand__c, Opportunity_Name__c, Exclude_Metro_Mobility__c FROM Session__c');
        //mapQueries.put('FPITest','SELECT Id, CreatedDate, LastModifiedDate, Allow_Multiple_Contacts_from_Household__c, IsAvailableForQC__c , IsAvailableToRecruit__c, Public_Test_Description__c, Population_Type__c, First_Session_Start__c, Ignore_Past_Participation__c, Last_Session_Start__c, Pairs_Test__c, Screener_Link__c, Project_Number__c, Project_List_Action__c, Qual_Day_Past_Participation_Exclude__c, Quant_Day_Past_Participation_Exclude__c, Minimum_Age__c, Maximum_Age__c, Required_Gender__c, Respondent_Type__c, Pairs_Maximum_Age__c, Pairs_Minimum_Age__c, Pairs_Qual_Day_Past_Particapati_Exclude__c, Pairs_Quant_Day_Past_Part_Excluded__c, Pairs_Required_Gender__c, Pairs_Screener_Link__c, Pairs_Test_Type__c, Info_Only_Survey__c, Info_Only_Type__c, Brand__c, Hide_on_App__c, Exclude_Metro_Mobility__c FROM Master_Test__c');
        mapQueries.put('FPITestRespondent','SELECT CreatedDate, Check_Amount__c, Check_Printed_Date__c, Check_Memo__c,Check_Number__c,Donation_Amount_Per_Event__c,Id,LastModifiedDate,Master_Test__c,Organization__c,Pair_Primary__c,Respondent_Status__c,Respondent__c,Tested_Status__c, Scheduler_Contact_ID__c, IsFPITestersVisible__c FROM Test_Respondent__c WHERE Respondent__c != null');
        mapQueries.put('FPITestRespondentQuota','SELECT Id, CreatedDate, LastModifiedDate, Session_Quota__c, Test_Respondent__c, Scheduling_Priority__c, IsPreQualified__c, IsQualified__c, IsAvailableForScheduling__c, IsScheduled__c, Session_Research_Type__c FROM Test_Respondent_Quota__c');
        mapQueries.put('FPIOpenMasterTests', 'SELECT Id, IsAvailableForQC__c, IsAvailableToRecruit__c, Info_Only_Survey__c, Hide_on_App__c, Brand__c, Exclude_Metro_Mobility__c FROM Master_Test__c WHERE IsAvailableToRecruit__c = TRUE');
        mapQueries.put('FPIOpenSessions', 'SELECT Id, RAF_Link__c, Related_Test__c, IsAvailableToRecruit__c, Brand__c, Exclude_Metro_Mobility__c FROM Session__c WHERE IsAvailableToRecruit__c = TRUE');
        mapQueries.put('FPIOpenQuotas', 'SELECT Id, MasterTestId__c, IsScheduleEnabled__c, IsOpen__c FROM Session_Quota__c WHERE IsOpen__c = TRUE');
        mapQueries.put('FPIPollHeader', 'SELECT Id, CreatedById, CreatedDate, CurrencyIsoCode, Description__c, End_Date__c, Image__c, IsDeleted, LastModifiedById, LastModifiedDate, Name, OwnerId, Start_Date__c, SystemModstamp, Title__c FROM Poll_Header__c ');
        mapQueries.put('FPIPollRespondent', 'SELECT Id, CreatedById, CreatedDate, CurrencyIsoCode, IsDeleted, LastModifiedById, LastModifiedDate, Name, OwnerId, Poll_Header__c, Respondent__c, Selected_Answer__c, SystemModstamp FROM Poll_Respondent__c ');
        mapQueries.put('FPIPollAnswer', 'SELECT Id, Answer_Text__c, CreatedById, CreatedDate, CurrencyIsoCode, IsDeleted, LastModifiedById, LastModifiedDate, Name, OwnerId, Poll_Header__c, Sort_Order__c, SystemModstamp FROM Poll_Answer__c ');
        mapQueries.put('TasteocracyPopulationDefinitionTopic','SELECT Id, Master_Test__c, CreatedDate, LastModifiedDate, Name, Allow_Multiple_Contacts_from_Household__c, IsAvailableForQC__c, IsAvailableToRecruit__c, Ignore_Past_Participation__c, Qual_Day_Past_Participation_Exclude__c, Quant_Day_Past_Participation_Exclude__c, Minimum_Age__c, Maximum_Age__c, Required_Gender__c, Respondent_Type__c, Pairs_Maximum_Age__c, Pairs_Minimum_Age__c, Pairs_Qual_Day_Past_Part_Excluded__c, Pairs_Quant_Day_Past_Part_Excluded__c, Pairs_Required_Gender__c, Pairs_Screener_Link__c, Pairs_Test__c, Pairs_Test_Type__c, Job_Function__c FROM Population_Definition__c');

        //mapQueries.put('FPIEngagementProfile', 'SELECT AmountEarned_Lifetime__c,AmountEarned_YTD__c,AmountPaid_Lifetime__c,AmountPaid_YTD__c,CreatedById,CreatedDate,CurrencyIsoCode,Disqualified_Lifetime__c,Disqualified_YTD__c,Id,IsDeleted,LastEngagementRecalcDate__c,LastModifiedById,LastModifiedDate,LastReferencedDate,LastViewedDate,Last_Profile_Survey_Completion_Date__c,Name,OwnerId,ProfileSurveyComplete__c,PSA_Lifetime__c,PSA_YTD__c,Qualified_Lifetime__c,Qualified_YTD__c,Referred_Lifetime__c,Referred_YTD__c,Respondent__c,SystemModstamp,Tested_Lifetime__c,Tested_YTD__c FROM EngagementProfile__c');
        //mapQueries.put('FPIEngagementTransaction', 'SELECT AmountEarned__c,AmountPaid__c,Category__c,CreatedById,CreatedDate,CurrencyIsoCode,EngagementProfile__c,Id,IsDeleted,LastModifiedById,LastModifiedDate,LastReferencedDate,LastViewedDate,Name,Notes__c,OwnerId,SystemModstamp,TransactionDate__c FROM EngagementTransaction__c');

        return mapQueries;
    }

    public static Map<Integer, String> STATUS_RESTSERVICE() {
        Map<Integer, String> mapStatusCodes = new Map<Integer, String>();
        mapStatusCodes.put(0, 'OPERATION_COMPLETED_SUCCESSFULLY');
        // Data and Processing Errors
        mapStatusCodes.put(1000, 'INPUT_JSON_STRUCTURE_ERROR_FOR_THIS_ACTION');
        mapStatusCodes.put(1001, 'MISSING_REQUIRED_ACTION');
        mapStatusCodes.put(1002, 'MISSING_REQUIRED_DATA');
        mapStatusCodes.put(1003, 'INVALID_ACTION');
        mapStatusCodes.put(1004, 'INVALID_OR_INCORRECTLY_STRUCTURED_REQUIRED_DATA');
        mapStatusCodes.put(1005, 'INVALID_OR_INCORRECTLY_STRUCTURED_OPTIONAL_DATA');
        // Business Logic Errors
        mapStatusCodes.put(2000, 'SCHEDULING_REQUEST_NOT_SUCCESSFUL_NO_REQUESTED_SESSIONS_AVAILABLE');
        mapStatusCodes.put(2001, 'SCHEDULING_CANCELLATION_NOT_SUCCESSFUL_NO_SCHEDULE_TO_CANCEL');
        mapStatusCodes.put(2002, 'QUOTA_CLOSED');
        // Exceptions and Acts of God!
        mapStatusCodes.put(9998, 'ACTION_NOT_IMPLEMENTED');
        mapStatusCodes.put(9999, 'CAUGHT_EXCEPTION_IN_WEBPROCESSOR_CONTACT_ADMINISTRATOR');
        return mapStatusCodes;
    }

    //07.22.2019    Sophia Murphy (Demand Chain)
    //              Added pollrespondentCreate
    public static Set<String> ACTIONS_RESTSERVICE() {
        Set<String> setActions = new Set<String>();
        setActions.add('householdManage');
        setActions.add('householdRefresh');
        setActions.add('householdRefreshDate');
        setActions.add('householdMemberManage');
        setActions.add('householdMemberRemove');
        setActions.add('householdMemberRefresh');
        setActions.add('screenerCreateStub');
        setActions.add('screenerAddResults');
        setActions.add('screenerResetSweeper');
        setActions.add('respondentSignup');
        setActions.add('respondentManage');
        setActions.add('respondentSchedule');
        setActions.add('respondentCancel');
        setActions.add('respondentRefresh');
        setActions.add('respondentCheck');
        setActions.add('respondentRefreshDate');
        setActions.add('testRespondentRefresh');
        setActions.add('testExcludedProjects');
        setActions.add('testRefresh');
        setActions.add('testRefreshDate');
        setActions.add('testAllOpenRecords');
        setActions.add('sessionRefresh');
        setActions.add('respondentSignin');
        setActions.add('createInitialProject');
		setActions.add('fundraisingSignup');
        setActions.add('pollRespondentCreate');
        setActions.add('confirmTesting');
        setActions.add('respondentCashOut');
        return setActions;
    }

    public static Id RECORDTYPE_ID(String objectAPIName, String recordTypeName) {
        Map<String, Schema.SObjectType> sobjectSchemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType sObjType = sobjectSchemaMap.get(objectAPIName) ;
        Schema.DescribeSObjectResult cfrSchema = sObjType.getDescribe() ;
        Map<String,Schema.RecordTypeInfo> RecordTypeInfo = cfrSchema.getRecordTypeInfosByName();
        Id recordTypeId = RecordTypeInfo.get(recordTypeName).getRecordTypeId();
        return recordTypeId;
    }

    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    // UTILITY METHODS AND TOOLS
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    public static void LOG_MESSAGE(String methodName, String errorMessage) {
        System.Debug(LOGGINGLEVEL.ERROR, '*** ' + methodName + ' *** : ' + errorMessage);
    }

    /**public static void determineSoundexKey(String strKeyField, String strComputeField) {
        for(sObject so : trigger.new) {
            so.put(strKeyField, UtilitySoundex.toSoundex(string.valueOf(so.get(strComputeField))));
        }
    }*/

    public static List<String> fieldsInObject(String strObjectName) {

        List<String> fieldsInObject = new List<String>();

        SObjectType objToken = Schema.getGlobalDescribe().get(strObjectName);
        DescribeSObjectResult objDef = objToken.getDescribe();
        Map<String, SObjectField> fields = objDef.fields.getMap();
        for(String str : fields.keyset()) {
            SObjectField fieldToken = fields.get(str);
            DescribeFieldResult selectedField = fieldToken.getDescribe();
            if(selectedField.isUpdateable()) {
                fieldsInObject.add(selectedField.getName() + '|' + selectedField.getLabel());
            }
        }

        return fieldsInObject;
    }

    public static Map<String, String> fieldLabelsForNames(String strObjectName) {

        Map<String, String> fieldLabelsForNames = new Map<String, String>();

        List<Schema.DescribeSObjectResult> describeSobjectsResult = Schema.describeSObjects(new List<String>{strObjectName});
        Map<String, Schema.SObjectField> allFields = describeSobjectsResult[0].fields.getMap();
        for(String str : allFields.keySet()) {
            fieldLabelsForNames.put(str, allFields.get(str).getDescribe().getLabel());
        }

        return fieldLabelsForNames;
    }

    // Returns a dynamic SOQL statement for the whole object, includes only creatable fields since we will be inserting a cloned result of this query
    public static string getCreatableFieldsSOQL(String objectName, String whereClause){
        String selects = '';
        if (whereClause == null || whereClause == ''){ return null; }
        // Get a map of field name and field token
        Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
        list<string> selectFields = new list<string>();

        if (fMap != null){
            for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
                Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                if (fd.isCreateable()){ // field is creatable
                    selectFields.add(fd.getName());
                }
            }
        }
        if (!selectFields.isEmpty()){
            for (string s:selectFields){
                selects += s + ',';
            }
            if (selects.endsWith(',')){selects = selects.substring(0,selects.lastIndexOf(','));}
        }
        return 'SELECT ' + selects + ' FROM ' + objectName + ' WHERE ' + whereClause;
    }

    // Returns a List<String> of all options in a picklist
    public static List<String> getValuesForPicklist(String objectAPIName, String fieldName) {
        List<String> lstPickvals=new List<String>();
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectAPIName);//From the Object Api name retrieving the SObject
        Sobject Object_name = targetType.newSObject();
        Schema.sObjectType sobject_type = Object_name.getSObjectType(); //grab the sobject that was passed
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); //describe the sobject
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
        List<Schema.PicklistEntry> pick_list_values = field_map.get(fieldName).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
        for (Schema.PicklistEntry a : pick_list_values) { //for all values in the picklist list
            lstPickvals.add(a.getValue());//add the value  to our final list
        }
        return lstPickvals;
    }
    public static string convertNumberToWord(string numToConvert)
    {
        string numberString = string.valueOf(numToConvert);
        string returnWord = '';
        Integer i=0;
        do
        {
            if(i<numberString.length())
            {
                returnWord = returnWord + ' ' + digitToWord(numberString.substring(i,i+1));
            }
            i++;
        }
        while(i < numberString.length());

        return returnWord.trim();
    }
    public static string digitToWord(string digit)
    {
        if(digit == '0') { return 'zero'; }
            else if(digit == '1') { return 'one'; }
            else if(digit == '2') { return 'two';  }
            else if(digit == '3') { return 'three'; }
            else if(digit == '4') { return 'four'; }
            else if(digit == '5') { return 'five'; }
            else if(digit == '6') { return 'six'; }
            else if(digit == '7') { return 'seven'; }
            else if(digit == '8') { return 'eight'; }
            else if(digit == '9') { return 'nine'; }
            else { return 'not a digit'; }
    }

    /**public static void determineZipZone(List<sObject> lstSObjects, String strSourceName, String strTargetName) {

        // Pull ZipZone List
        Map<String, String> mapZones = ZIP_ZONES();

        for(SObject so : lstSObjects) {

            if(string.valueOf(so.get(strSourceName)) != null) {

                // Strip out any 9-character zips, only 5-digit!
                String strZip = string.valueOf(so.get(strSourceName));
                Integer intLength = strZip.length();
                if(intLength > 5) { intLength = 5; }
                strZip = strZip.left(intLength);

                // Determine if Zip Code Exists
                if(mapZones.containsKey(strZip)) {
                    so.put(strTargetName, mapZones.get(strZip));
                } else {
                    so.put(strTargetName, 'Unknown Zone');
                }
            }
        }
    }*/

    public static String convertLongZipToShort(String strZipCode) {
        if(strZipCode == null) {
            return null;
        }
        Integer intLength = strZipCode.length();
        if(intLength > 5) { intLength = 5; }
        return strZipCode.left(intLength);
    }

    /**public static void determineLocalTestingCenters(List<sObject> lstSObjects, String strSourceName, String str5Mile, String str10Mile, String str15Mile) {

        System.Debug('UtilityMethods.determineLocalTestingCenters SOQL LIMIT START: ' + Limits.getQueries());

        // Create Comparison List
        Set<String> setSourceZipCodes = new Set<String>();
        Set<String> setZipCodes = new Set<String>();
        Map<String, List<hClsLatLongMatrix>> mapDistanceMatrix = new Map<String, List<hClsLatLongMatrix>>();

        // First - pull all Testing Center Accounts
        Set<String> setTestingCenterRTNames = new Set<String>();
        setTestingCenterRTNames.add('Local_Testing_Location');
        setTestingCenterRTNames.add('Remote_Testing_Location');
        Map<String, Account> mapCenters = new Map<String, Account>();
        for(Account acct : [SELECT Id, Site_Code__c, BillingPostalCode FROM Account
                                WHERE RecordType.DeveloperName IN :setTestingCenterRTNames
                                AND BillingPostalCode != null
                                AND Site_Code__c != null
                                AND Include_With_Respondent_Zone__c = true]) {
            acct.BillingPostalCode = convertLongZipToShort(acct.BillingPostalCode);
            mapCenters.put(acct.Site_Code__c, acct);
            setZipCodes.add(acct.BillingPostalCode);
        }

        // First - pull all Zips from the List<sObject> coming in
        for(sObject so : lstSObjects) {
            setSourceZipCodes.add(convertLongZipToShort(string.valueOf(so.get(strSourceName))));

            // Strip out any 9-character zips, only 5-digit!
            if(string.valueOf(so.get(strSourceName)) != null) {
                setZipCodes.add(convertLongZipToShort(string.valueOf(so.get(strSourceName))));
            }
        }

        // First Calc all possible iterations based on zip/zone table
        Map<String, Zip_Code_Zones__c> mapZips = new Map<String, Zip_Code_Zones__c>();
        for(Zip_Code_Zones__c zip : [SELECT Name, Lat__c, Long__c, Zone__c FROM Zip_Code_Zones__c WHERE Name IN :setZipCodes]) {
            mapZips.put(zip.Name, zip);
        }

        System.debug('------------------------------------');
        System.Debug('mapCenters - ' + mapCenters);
        System.debug('------------------------------------');

        // Loop through and make map of available zip/zones by zip in sObject list
        for(sObject so : lstSObjects) {
            List<hClsLatLongMatrix> lstDistanceSublist = new List<hClsLatLongMatrix>();

            String strLat = convertLongZipToShort(string.valueOf(so.get(strSourceName)));
            String strLong = convertLongZipToShort(string.valueOf(so.get(strSourceName)));

            if(strLat != null && strLong != null) {
                System.Debug('CHECKING TO SEE IF ' + strLat + ' EXISTS IN MAP');
                if(mapZips.containsKey(strLat)) {
                    System.Debug('SUCCESS!  ' + strLat + ' EXISTS IN MAP');
                    Decimal decSourceLat = mapZips.get(strLat).Lat__c;
                    Decimal decSourceLong = mapZips.get(strLong).Long__c;

                    for(Account acct : mapCenters.values()) {

                        System.Debug('CHECKING FOR ' + acct.BillingPostalCode);

                        // Change long zip to 5 digit
                        if(mapZips.containsKey(acct.BillingPostalCode)) {
                            System.Debug('MAP CONTAINS KEY, PROCESSING ' + acct.BillingPostalCode);

                            Decimal decTargetLat = mapZips.get(acct.BillingPostalCode).Lat__c;
                            Decimal decTargetLong = mapZips.get(acct.BillingPostalCode).Long__c;

                            //if(string.valueOf(so.get(strSourceName)) != acct.BillingPostalCode) {
                                Decimal decDistance = calculateHaversineDistance(decSourceLat, decSourceLong, decTargetLat, decTargetLong);
                                lstDistanceSublist.add(new hClsLatLongMatrix(acct.Site_Code__c, acct.BillingPostalCode, decDistance));
                            //}
                        }
                    }
                }
            }
            lstDistanceSublist.sort();
            mapDistanceMatrix.put(convertLongZipToShort(string.valueOf(so.get(strSourceName))), lstDistanceSublist);
        }

        System.debug('------------------------------------');
        System.Debug('mapDistanceMatrix - ' + mapDistanceMatrix);
        System.debug('------------------------------------');

        // Go through source zip codes and pull lists 0-5, 5.000001-10, 10.000001-15
        for(sObject so : lstSObjects) {
            if(so.get(strSourceName) == null) {
                so.put(str5Mile,'');
                so.put(str10Mile,'');
                so.put(str15Mile,'');
            } else {
                Set<String> set5Mile = new Set<String>();
                Set<String> set10Mile = new Set<String>();
                Set<String> set15Mile = new Set<String>();

                for(hClsLatLongMatrix centerRad : mapDistanceMatrix.get(convertLongZipToShort(string.valueOf(so.get(strSourceName))))) {
                    if(centerRad.decDistanceInMiles < 5) {
                        set5Mile.add(centerRad.strSiteName);
                    }
                    if(centerRad.decDistanceInMiles > 5.0000001 && centerRad.decDistanceInMiles < 10) {
                        set10Mile.add(centerRad.strSiteName);
                    }
                    if(centerRad.decDistanceInMiles > 10.0000001 && centerRad.decDistanceInMiles < 15) {
                        set15Mile.add(centerRad.strSiteName);
                    }
                }

                so.put(str5Mile,'');
                so.put(str10Mile,'');
                so.put(str15Mile,'');

                String strOutput5Mile = '';
                String strOutput10Mile = '';
                String strOutput15Mile = '';

                //for(string str : set5Mile) { so.put(str5Mile,so.get(str5Mile)+string.valueOf(str)+';'); }
                //for(string str : set10Mile) { so.put(str10Mile,so.get(str10Mile)+string.valueOf(str)+';'); }
                //for(string str : set15Mile) { so.put(str15Mile,so.get(str15Mile)+string.valueOf(str)+';'); }

                for(string str : set5Mile) { strOutput5Mile+=string.valueOf(str)+';'; }
                for(string str : set10Mile) { strOutput10Mile+=string.valueOf(str)+';'; }
                for(string str : set15Mile) { strOutput15Mile+=string.valueOf(str)+';'; }

                // Check for Max 255 Char Length!
                if(strOutput5Mile.length() > 255) { strOutput5Mile = strOutput5Mile.substring(0,254); }
                if(strOutput10Mile.length() > 255) { strOutput10Mile = strOutput10Mile.substring(0,254); }
                if(strOutput15Mile.length() > 255) { strOutput15Mile = strOutput15Mile.substring(0,254); }

                so.put(str5Mile,strOutput5Mile);
                so.put(str10Mile,strOutput10Mile);
                so.put(str15Mile,strOutput15Mile);
            }
        }

        System.Debug('UtilityMethods.determineLocalTestingCenters SOQL LIMIT END: ' + Limits.getQueries());

    }*/

    public static Decimal calculateHaversineDistance(Decimal lat1, Decimal lon1, Decimal lat2, Decimal lon2){
        // Earth's radius varies from 6356.752 km at the poles to 6378.137 km at the equator
        Double radius = 6371.00;
        Double dLat = toRadians(lat2-lat1);
        Double dLon = toRadians(lon2-lon1);
        Double a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
        Double c = 2 * Math.asin(Math.sqrt(a));

        double kmToMiles = 0.621371;
        Decimal retVal = radius * c * kmToMiles;
        System.Debug('computing ' + retVal);
        return retVal;
    }

    private static Double toRadians(Decimal degree){
        return degree * 3.1415926 / 180;
    }

    global class hClsLatLongMatrix implements Comparable {

        String strSiteName;
        String strTargetZip;
        Decimal decDistanceInMiles;

        public hClsLatLongMatrix(String siteName, String targetZip, Decimal distance) {
            strSiteName = siteName;
            strTargetZip = targetZip;
            decDistanceInMiles = distance;
        }

        public Integer compareTo(Object compareTo) {
            hClsLatLongMatrix latLongMatrix = (hClsLatLongMatrix) compareTo;
            if (decDistanceInMiles == latLongMatrix.decDistanceInMiles) return 0;
            if (decDistanceInMiles > latLongMatrix.decDistanceInMiles) return 1;
            return -1;
        }

    }

    public static string wordToNumber(Decimal i, String curr) {
        String text='';
        String bigD='', smallD='';
        Decimal Bn=0, Gn=0, Kn=0, Hn=0, Dn=0, tDn=0, dec=0;
        Integer n=0;

        String[] ones = new String[]{'', 'One', 'Two', 'Three', 'Four', 'Five', 'Six',
        'Seven', 'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen',
        'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eightteen',
        'Nineteen'};
        String[] tens = new String[]{'', 'Twenty', 'Thirty', 'Fourty', 'Fifty', 'Sixty',
        'Seventy', 'Eigthy', 'Ninety'};
        //More currencies can be added
        if(curr == 'USD'){ bigD='Dollar'; smallD='Cent';}
        else if(curr == 'IRD'){ bigD='Rupiah'; smallD='Sen';}

        if((i==null)||(i < 0 )|| (i > 99999999999.99))
          return '';

        Bn = math.floor(i/100000000); //Billion
        i=i-Bn*100000000;
        Gn = math.floor(i/1000000); //Million
        i=i-Gn*1000000;
        Kn = math.floor(i/1000); //Thousand
        i=i-Kn*1000;
        Dn = math.floor(i/100); //Hundred
        if(Dn ==0)
          tDn =math.floor(i/10);
        else
          tDn =math.floor(math.mod(integer.valueof(i),100)/10);
        dec = math.mod(math.mod(integer.valueof(i*100),100), 100);
        i=i-Dn*100;

        n=math.mod(integer.valueof(i),10); //Ones

        if(Bn !=0)
          text = text + wordToNumber(Bn, curr)+ ' Billion ';
        if(Gn !=0)
          text = text + wordToNumber(Gn, curr)+ ' Million ';
        if(Kn !=0)
          text = text + wordToNumber(Kn, curr)+ ' Thousand ';
        if(Dn !=0)
          text = text + wordToNumber(Dn, curr)+ ' Hundred ';


        if(tDn !=0 || n !=0){
          if(text!='')
              text = text + ' and ';
          if(tDn <2){
              text = text + ones[integer.valueof(tDn)*10 + n];
          }else{
              text = text + tens[integer.valueof(tDn)-1];
              if(n!=0)
                  text = text + ' - ' + ones[n];
          }
        }
        if(dec !=0){
          text = text +' '+bigD+' and '+ wordToNumber(dec, curr) + ' '+smallD;
        }
        if(text == '')
          text = 'zero';

        return text;
    }

    static String[] to_19 = new string[]{ 'Zero', 'One',  'Two', 'Three', 'Four',  'Five',  'Six',
    'Seven', 'Eight', 'Nine', 'Ten',  'Eleven', 'Twelve', 'Thirteen',
    'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen' };
    static String[] tens = new string[]{ 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'};
    static String[] denom = new string[]{ '',
    'Thousand',   'Million',     'billion',    'trillion',    'quadrillion',
    'quintillion', 'sextillion',   'septillion',  'octillion',   'nonillion',
    'decillion',  'undecillion',   'duodecillion', 'tredecillion',  'quattuordecillion',
    's!xdecillion', 'septendecillion', 'octodecillion', 'novemdecillion', 'vigintillion' };

    // convert a value < 100 to English.
    public static String convert_nn(integer val) {
        if (val < 20)
            return to_19[val];
        if(val == 100)
            return 'One Hundred';
        for (integer v = 0; v < tens.size(); v++) {
            String dcap = tens[v];
            integer dval = 20 + 10 * v;
            if (dval + 10 > val) {
                if (Math.Mod(val,10) != 0)
                    return dcap + ' ' + to_19[Math.Mod(val,10)];
                return dcap;
            }
        }
        return 'Should never get here, less than 100 failure';
    }

    // convert a value < 1000 to english, special cased because it is the level that kicks
    // off the < 100 special case. The rest are more general. This also allows you to
    // get strings in the form of "forty-five hundred" if called directly.
    public static String convert_nnn(integer val) {
        String word = '';
        integer rem = val / 100;
        integer mod = Math.mod(val,100);
        if (rem > 0) {
            word = to_19[rem] + ' hundred';
            if (mod > 0) {
                word += ' ';
            }
        }
        if (mod > 0) {
            word += convert_nn(mod);
        }
        return word;
    }

    public static String english_number(long val) {
        if (val < 100) {
            return convert_nn(val.intValue());
        }
        if (val < 1000) {
            return convert_nnn(val.intValue());
        }
        for (integer v = 0; v < denom.size(); v++) {
            integer didx = v - 1;
            integer dval = (integer)Math.pow(1000, v);
            if (dval > val) {
                integer mod = (integer)Math.pow(1000, didx);
                integer l = (integer) val / mod;
                integer r = (integer) val - (l * mod);
                String ret = convert_nnn(l) + ' ' + denom[didx];
                if (r > 0) {
                    ret += ', ' + english_number(r);
                }
                return ret;
            }
        }
        return 'Should never get here, bottomed out in english_number';
    }

    // public Set<String> userResourcePools() {

    //     Set<String> setTemp = new Set<String>();

    //     for(User usr : [SELECT ATCFPI__Resource_Pool__c FROM User WHERE ATCFPI__Resource_Pool__c != '']) {
    //         for(String strRole : usr.ATCFPI__Resource_Pool__c.split(';')) {
    //             setTemp.add(strRole);
    //         }
    //     }

    //     return setTemp;

    // }

    public static Decimal checkForNullNumber(Decimal passNumber) {
        if(passNumber == null) {
            return 0;
        }
        return passNumber;
    }

    public static String checkForNull(Object objSource) {

        String retValue = '';

        if(objSource instanceof String && ((String) objSource).trim().length() > 0) {
            retValue = ((String) objSource);
        }

        return retValue;
    }

    public Static Boolean isSandbox(){

        System.Debug('DETERMINING IF THIS IS SANDBOX OR NOT');
        Boolean isSandboxParse = false;

        //04.11.2019 - Sophia Murphy (Demand Chain)
        //To cut down on queries - using UserInfo to get the Sandbox vs. Prod
        // using the Organization Id - and it's hard coded, don't scold me - this is a hot fix.
        // and I'm only looking at the Prod Id - if it's not the prod id, then it's sandbox
        Id orgId = UserInfo.getOrganizationId();
        if(orgId == '00DU0000000LYcXMAW') {
            isSandboxParse = false;
        } else {
            isSandboxParse = true;
        }
        return isSandboxParse;
    }

    public static String stringSetToCSV(Set<String> setString, Boolean bolEncapQuoteMarks) {
        String strReturn = '';

        String strEncapStart = '\'';
        String strEncapEnd = '\'';

        if(!bolEncapQuoteMarks) { strEncapStart = ''; strEncapEnd = ''; }

        for(String objStr : setString) {
            strReturn += (strReturn==''?'':',')+strEncapStart+objStr+strEncapEnd;
        }
        return strReturn;
    }
    
    public static String findObjectNameFromRecordIdPrefix(String recordIdOrPrefix){
        String objectName = '';
        try{
            //Get prefix from record ID
            //This assumes that you have passed at least 3 characters
            String myIdPrefix = String.valueOf(recordIdOrPrefix).substring(0,3);
             
            //Get schema information
            Map<String, Schema.SObjectType> gd =  Schema.getGlobalDescribe(); 
             
            //Loop through all the sObject types returned by Schema
            for(Schema.SObjectType stype : gd.values()){
                Schema.DescribeSObjectResult r = stype.getDescribe();
                String prefix = r.getKeyPrefix();
                System.debug('Prefix is ' + prefix);
                 
                //Check if the prefix matches with requested prefix
                if(prefix!=null && prefix.equals(myIdPrefix)){
                    objectName = r.getName();
                    System.debug('Object Name! ' + objectName);
                    break;
                }
            }
        }catch(Exception e){
            System.debug(e);
        }
        return objectName;
    }

    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    // WEB CALLOUTS AND INTEGRATIONS
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////

    public static void sendSAPITriggerWrapper(String strQueue) {

        System.Debug('RECEIVED SQS REQUEST FOR ' + strQueue);

        UtilityMethods.sendSAPIWrapper(strQueue, null, null);
    }

    public static void sendSAPIWrapper(String strSQSQueue, String strOperation, Set<Id> setIds, Boolean bolRetry) {
        UtilityMethods.sendSAPIWrapper(strSQSQueue, strOperation, setIds);
    }

    public static void sendSAPIWrapper(String strSQSQueue, String strOperation, Set<Id> setIds) {

        // Protect against limit breach on DML and SOQL
        if(limits.getQueries() >= limits.getLimitQueries()) {
            return;
        }

        // Determine Scope
        if(trigger.isExecuting) {
            if(trigger.isInsert || trigger.isUndelete) { strOperation = 'insert'; setIds = trigger.newMap.keyset(); }
            if(trigger.isUpdate) { strOperation = 'update'; setIds = trigger.newMap.keyset(); }
            if(trigger.isDelete) { strOperation = 'delete'; setIds = trigger.oldMap.keyset(); }
        } else {
            // If no Ids are passed, just end processing
            if(setIds == null) {
                System.Debug('NULL SIZE SET FOR SQS ' + strSQSQueue + ' - ' + strOperation + ' PUSH, TERMINATING');
                return;
            }
        }

        Map<String, String> mapQueries = UtilityMethods.SQS_QUEUES();
        String strQuery = mapQueries.get(strSQSQueue);

        if(strQuery.indexOf('WHERE') == -1) {
            strQuery+= ' WHERE Id IN :setIds';
        } else {
            strQuery+= ' AND Id IN :setIds';
        }

        // Append DEV vs. PROD in the SQS Queue String
        if(UtilityMethods.isSandbox()) {
            strSQSQueue+= 'Dev';
        } else {
            strSQSQueue+= 'Prod';
        }

        // Query and return Map
        Map<Id, sObject> mapRecords;

        if(trigger.isExecuting && trigger.isDelete) {
            mapRecords = new Map<Id, sObject>();
            for(sObject so : trigger.old) {
                mapRecords.put((Id)so.get('Id'), so);
            }
        } else {
            mapRecords = new Map<Id, sObject>(Database.query(strQuery));
        }


        // If no Results are passed, just end processing
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
    }

    public static String prepareSAPICalloutPayload(String queue, String operation, List<sObject> records) {
        hClsFPITestersCalloutWrapper clsWrapper = new hClsFPITestersCalloutWrapper(queue, operation, records);
        return JSON.serialize(clsWrapper);
    }

    public static void sendBulkLogglyMessage(List<String> lstTags, Set<Id> setIds) {
        UtilityMethods.sendBulkLogglyMessageFull(lstTags, setIds, '');
    }

    public static void sendBulkLogglyMessageFull(List<String> lstTags, Set<Id> setIds, String strBody) {

        // Parse up events
        String strData = strBody;
        if(setIds != null) {
            for(Id recordId : setIds) {
                strData+=recordId+'\n';
            }
        }


        // this should come from config somewhere
        String api_key = 'ec137b3d-51cd-4066-ac74-8a8b9133f4c9';

        // objects to make the request
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        Http http = new Http();

        // setup the request
        request.setEndpoint('https://logs-01.loggly.com/bulk/'+api_key);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'text/plain');

        // add tags in the header
        request.setHeader('X-LOGGLY-TAG', String.join(lstTags, ','));

        // put the log message in the body
        request.setBody(strData);

        if(!Test.isRunningTest()) {
            try {
                // send the request to Loggly
                response = http.send(request);
            } catch(System.CalloutException e) {
                System.debug('Loggly error: ' + e);
            }
        }

        System.debug(response.toString());

    }

    @Future(callout=true)
    public static void processOutboundSQSFuture(String strSQSQueue, String strJSONPayload, List<String> lstTags, Set<Id> setIds) {
        UtilityMethods.LOG_MESSAGE('UtilityMethods.processOutboundSQSFuture', 'Starting FUTURE Method to send SQS');
        UtilityMethods.processOutboundSQS(strSQSQueue, strJSONPayload, lstTags, setIds);
    }

    public static void processOutboundSQS(String strSQSQueue, String strJSONPayload, List<String> lstTags, Set<Id> setIds) {

        System.Debug('UtilityMethods.processOutboundSQS INFO:  Sending ' + strSQSQueue + ' to the SQS Processor');
        System.Debug(strJSONPayload);
        System.Debug(setIds);

        String strMessageId = Utility_AmazonSQSSender.sendMessageSignature4(strSQSQueue, strJSONPayload);

        // Add returned SQS MessageId to tag list
        lstTags.add(strMessageId);

        UtilityMethods.sendBulkLogglyMessage(lstTags, setIds);
    }

    @Future(callout=true)
    public static void sendFutureSAPICalloutToAmazon(String strSQSQueue, String strJSONPayload) {
        UtilityMethods.sendSAPICalloutToAmazon(strSQSQueue, strJSONPayload);
    }

    public static void sendSAPICalloutToAmazon(String strSQSQueue, String strJSONPayload) {
        Utility_AmazonSQSSender.sendMessageSignature4(strSQSQueue, strJSONPayload);
    }

    public static String encodeString(String strToEncode) {
        return EncodingUtil.base64Encode(Blob.valueof(strToEncode));
    }

    public static String decodeString(String strToDecode) {
        Blob blbDecode = EncodingUtil.base64Decode(strToDecode);
        return blbDecode.toString();
    }

    public static List<String> fieldSetFields(String sObjectName, String sFieldSetName) {
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sObjectName.toLowerCase());
        //system.debug('DC: FS: ' + targetType);
      
        List<String> fieldNames = new List<String>();
        Set<String> fieldSetNames = new Set<String>();

        //Get ALL the fields from the object
        Map<String, Schema.SObjectField> fieldMap = targetType.getDescribe().fields.getMap();
        //system.debug('DC: FS: ' + fieldMap);

        //Get ALL the fields that are in the fieldset...
        Schema.FieldSet objFieldSet = targetType.getDescribe().fieldSets.getMap().get(sFieldSetName);
        //system.debug('DC: FS: ' + objFieldSet);

        //Loop through the fieldset and add those field names to a set...
        for(Schema.FieldSetMember f : objFieldSet.getFields()) {
            fieldSetNames.add(f.getFieldPath());
        }
        //system.debug('DC: FS: ' + fieldSetNames);

        //Loop through the fieldset set... and then check that that field is editable
        //for(String fieldName : fieldMap.keySet()) {
        for(String fieldName : fieldSetNames) {
            //system.debug('DC: FS: ' + fieldName);
            try {         
                fieldNames.add(fieldName);
            } catch (Exception e) {
                System.debug('DC: Issue with fieldName: ' + fieldName);
            }
        }
        return fieldNames; 
    }

    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    // INNER CLASSES
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    public class hClsFPITestersCalloutWrapper {
        public String queue {get;set;}
        public String operation {get;set;}
        public List<sObject> records {get;set;}

        public hClsFPITestersCalloutWrapper(String passSQSQueue, String passOperation, List<sObject> passRecords) {
            queue = passSQSQueue;
            operation = passOperation;
            records = passRecords;
        }
    }

    public class hClsSessionQuotaCounts {
        public Integer intQ {get;set;}
        public Integer intPQ {get;set;}
        public Integer intS {get;set;}
        public Integer intTotal {get;set;}

        public Session_Quota__c objSQ {get;set;}
        public Quota__c objMQ {get;set;}
        public Session__c objS {get;set;}

        public Boolean bolSQChanged {get;set;}
        public Boolean bolMQChanged {get;set;}
        public Boolean bolSChanged {get;set;}

        public hClsSessionQuotaCounts() {
            intQ = 0;
            intPQ = 0;
            intS = 0;
            intTotal = 0;

            bolSQChanged = false;
            bolMQChanged = false;
            bolSChanged = false;
        }
    }

    public class hClsMetricAssist {
        public String strSQSQueue {get;set;}
        public String strJSONPayload {get;set;}
    }

    public class hClsValtiraCheckGenerator {
        public List<Map<String, List<CheckGeneratorController.valtiraField>>> formFields {get;set;}
        public Map<Id, Session__c> mapUpdateSessions {get;set;}
        public Id idMasterTest {get;set;}
        public List<Test_Respondent__c> lstRespondents {get;set;}

        public hClsValtiraCheckGenerator() {
            formFields = new List<Map<String, List<CheckGeneratorController.valtiraField>>>();
            mapUpdateSessions = new Map<Id, Session__c>();
            idMasterTest = null;
            lstRespondents = new List<Test_Respondent__c>();
        }
    }
}