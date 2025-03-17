/**
 * A comma delimited list of Master Tests to process is stored in Custom Settings: 
 * FPI Application Settings -> Profile_MasterTestIds
 * 
 * Batch size for this is stored in Profile_Update_BatchSize
 * 
 * A mapping of the Decipher JSON keys/values to map is stored in Custom Metadata:
 * Profile_Update__mdt
 * 
 * This can be scheduled, or run manually. 
 *		Batch_ProfileAutoUpdate batchClass = new Batch_ProfileAutoUpdate(); 
 		Database.ExecuteBatch(batchClass, 100);
 */
/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name / Description
*   2022.08.19  Sophia Murphy (Demand Chain)
*               Initial Creation
*   2023.05.30  Sophia Murphy (Demand Chain)
*               Update to find Households, the Household__c field on the respondent is rarely filled in.
*               Added in "TESTING IDs" option
*   2023.09.07  Sophia Murphy (Demand Chain)
*               Added in - "if blank option" for address items
*   =============================================================================
*/
global class Batch_ProfileAutoUpdate implements Database.Batchable<sObject> , Schedulable, Database.Stateful {
    
	public String query;
    public Map<String, String> fieldMultiPicklistMap;
    
    global Batch_ProfileAutoUpdate() 
    {
        //Get the Master Test Ids from Custom Settings
        String mtIds = FPI_AppSettings__c.getValues('Profile_MasterTestIds').Value__c;
        String mtQuery = '(\'';
        List<String> mtIds_List = mtIds.split(',');
        for(String mtId : mtIds_List) {
            mtQuery += mtId + '\',\'';
        }
        mtQuery += mtIds_List[0] + '\')';

        //Check if we are testing against a SINGLE Test Respondent
        String trIds = FPI_AppSettings__c.getValues('Profile_TestRespondentTestIds').Value__c;
        String trQuery = '';
        if(trIds != '' && trIds != null) {
            trQuery = '(\'';
            List<String> trIds_List = trIds.split(',');
            for(String trId : trIds_List) {
                trQuery += trId + '\',\'';
            }
            trQuery += trIds_List[0] + '\')';
        }

    	this.query = 'SELECT Id, Master_Test__c, Respondent__c, Screener_Results__c FROM Test_Respondent__c ';
        if(trQuery != '' && trQuery != null) {
            this.query += ' WHERE Id IN ' + trQuery + ' ';
        } else {
            this.query += ' WHERE Master_Test__c IN ' + mtQuery + ' AND Profile_Update_Processed__c = false AND Respondent_Status__c = \'Qualified\' AND Respondent__c != null ';
        }
        if(Test.isRunningTest())
        {
            this.query += ' LIMIT 200' ;
        }

    	System.debug('DC: query ' + query ) ;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) 
    {
    	return Database.getQueryLocator(query);
    }
    
    global void execute(SchedulableContext sc) 
    {
        
        String batchSize_String = FPI_AppSettings__c.getValues('Profile_Update_BatchSize').Value__c;
        Integer batchSize_Integer = Integer.valueOf(batchSize_String);

        if(batchSize_Integer == null || batchSize_Integer < 0 || batchSize_Integer > 200) {
            batchSize_Integer = 200;
        }
        
        Batch_ProfileAutoUpdate b = new Batch_ProfileAutoUpdate(); 
        database.executebatch(b, batchSize_Integer);
    }

    global void execute(Database.BatchableContext BC, List<Test_Respondent__c> scope) 
    {
        String CONST_DIRECTCOPY = 'DIRECTCOPY';

        //Loop through the TRs and get the Contact Ids
        Set<Id> contactIds = new Set<Id>();
        for(Test_Respondent__c tr : scope) {
            contactIds.add(tr.Respondent__c);
        }
        //Query for all households that have these contacts - make a map of Contact Ids to Households Id
        Map<Id, Id> contactToHousehold = new Map<Id, Id>();
        for(Household_Contact__c hc : [SELECT Id, Contact__c, Household__c FROM Household_Contact__c WHERE Contact__c IN :contactIds]) {
            if(hc.Contact__c != null && hc.Household__c != null) {
                contactToHousehold.put(hc.Contact__c, hc.Household__c);
            }
        }


        
        //1. Get the Custom Metadata from Profile Update
        Map<String, Map<String, List<Profile_Update__mdt>>> surveyKey_surveyValueMap = new Map<String, Map<String, List<Profile_Update__mdt>>>();
            /**
                Example: Map< SURVEY KEY, Map< SURVEY VALUE, List< OTHER INFO > > >
                survey key: income
                    survey value: 2
                        profile: Contact, Income, Less than 15k
                        profile: Household, Income, Less than 15k
                survey key: gender
                    survey value: 1
                        profile: Contact, Gender, Male
                    survey value: 2
                        profile: Contact, Gender, Female
                survey key: numberofkids
                    survey value: DIRECTCOPY (Direct Copy Checked)
                        profile: Contact, Num of Kids, DIRECTCOPY
            */
        for(Profile_Update__mdt pu : [SELECT Survey_Key__c, Survey_Value__c, Survey_Value_Direct_Copy__c
                                            , Salesforce_Object__c, Salesforce_Field_API_Name__c, Salesforce_Value__c
                                            , Salesforce_Field_Type__c
                                            , If_Blank_Value_Ignore__c
                                        FROM Profile_Update__mdt
                                        WHERE Is_Active__c = true]) {

            String surveyKey = pu.Survey_Key__c.toLowerCase();
            
            Map<String, List<Profile_Update__mdt>> tmpValueMap = surveyKey_surveyValueMap.get(surveyKey);
            if(tmpValueMap == null) {
                tmpValueMap = new Map<String, List<Profile_Update__mdt>>();
            }
            List<Profile_Update__mdt> tmpPUList = tmpValueMap.get(pu.Survey_Value__c);
            if(tmpPUList == null) {
                tmpPUList = new List<Profile_Update__mdt>();
            }

            tmpPUList.add(pu);
            tmpValueMap.put(pu.Survey_Value__c, tmpPUList);
            if(pu.Survey_Value_Direct_Copy__c == true) {
                tmpValueMap.put(CONST_DIRECTCOPY, tmpPUList);
            }
            surveyKey_surveyValueMap.put(surveyKey, tmpValueMap);
        }

        //2. Parse out the Screener Results and get in a map
        //List<Contact> contactUpdates = new List<Contact>();
        //List<Household__c> hhUpdates = new List<Household__c>();

        Map<Id, Contact> contactUpdates = new Map<Id, Contact>();
        Map<Id, Household__c> hhUpdates = new Map<Id, Household__c>();
        List<Test_Respondent__c> trUpdates = new List<Test_Respondent__c>();

        for(Test_Respondent__c tr: scope) {
            Map<String, String> keyValuePairs = new Map<String, String>();
            fieldMultiPicklistMap = new Map<String, String>();
                //Example Data: key: Contact-Disabilities__c - value: Disab1; Disab2; 

            // Put all in list first
            List<hScreenerResults> lstAll = new List<hScreenerResults>();
            if(tr.Screener_Results__c != null) {
                lstAll = (List<hScreenerResults>)JSON.deserialize(tr.Screener_Results__c, List<hScreenerResults>.class);
                system.debug('DC: lstAll: ' + lstAll);
                for(hScreenerResults clsQ : lstAll) {
                    keyValuePairs.put(clsQ.key.toLowerCase(), clsQ.value);
                }
            }
            
            //3. Now we have the keyValuePairs - see if they exist in the surveyKey maps...
            for(String surveyKey : keyValuePairs.keySet()) {
                system.debug('DC: surveyKey: ' + surveyKey);

                Boolean doAdd_Contact = false;
                Boolean doAdd_Household = false;

                String surveyValue = keyValuePairs.get(surveyKey);
                system.debug('DC: surveyValue: ' + surveyValue);

                Map<String, List<Profile_Update__mdt>> surveyValueMap = surveyKey_surveyValueMap.get(surveyKey);
                system.debug('DC: surveyValueMap: ' + surveyValueMap);

                if(surveyValueMap != null) {
                    List<Profile_Update__mdt> puMap = surveyValueMap.get(surveyValue);
                    system.debug('DC: puMap: ' + puMap);

                    List<Profile_Update__mdt> puMap_DirectCopy = surveyValueMap.get(CONST_DIRECTCOPY);
                    system.debug('DC: puMap_DirectCopy: ' + puMap_DirectCopy);

                    if(puMap != null || puMap_DirectCopy != null) {

                        //Ok - we have a record... build out a Contact and a HH record
                        Contact tmpContact = contactUpdates.get(tr.Respondent__c);
                        if(tmpContact == null) {
                            tmpContact = new Contact(Id = tr.Respondent__c);
                        }

                        Boolean householdPresent = false;
                        Id hhId = contactToHousehold.get(tr.Respondent__c);
                        Household__c tmpHH;
                        if(hhId != null) {
                            tmpHH = hhUpdates.get(hhId);
                            if(tmpHH == null) {
                                tmpHH = new Household__c(Id = hhId);
                            }
                            householdPresent = true;
                        }
                        

                        //Now - loop through the PU List and add in the fields...
                        if(puMap != null) {
                            for(Profile_Update__mdt pu : puMap) {

                                sObject tmpSO;
                                if(pu.Salesforce_Object__c == 'Contact') {
                                    doAdd_Contact = true;
                                    tmpSO = tmpContact;
                                }
                                if(pu.Salesforce_Object__c == 'Household__c' && householdPresent) {
                                    doAdd_Household = true;
                                    tmpSO = tmpHH;
                                }
                                tmpSO = processKeyValue(pu, tmpSO, pu.Salesforce_Value__c);
                            } //END: for(Profile_Update__mdt pu : puMap)
                        }

                        //Now for the DIRECT COPY
                        if(puMap_DirectCopy != null) {
                            for(Profile_Update__mdt pu : puMap_DirectCopy) {
                                if(pu.If_Blank_Value_Ignore__c == true && (surveyValue == '' || surveyValue == null)) {
                                    //Do nothing.  We are ignoring this one because the surveyValue is blank
                                } else {
                                    sObject tmpSO;
                                    if(pu.Salesforce_Object__c == 'Contact') {
                                        doAdd_Contact = true;
                                        tmpSO = tmpContact;
                                    }
                                    if(pu.Salesforce_Object__c == 'Household__c' && householdPresent) {
                                        doAdd_Household = true;
                                        tmpSO = tmpHH;
                                    }
                                    tmpSO = processKeyValue(pu, tmpSO, surveyValue);
                                }
                                
                            } //END: for(Profile_Update__mdt pu : puMap_DirectCopy)
                        }

                        if(doAdd_Contact) {
                            contactUpdates.put(tr.Respondent__c, tmpContact);
                        }
                        if(doAdd_Household) {
                            hhUpdates.put(hhId, tmpHH);
                        }

                    } //END: if(puMap != null || puMap_DirectCopy != null)

                } //END: if(surveyValueMap != null)
            } //END: for(String surveyKey : keyValuePairs.keySet())

            Test_Respondent__c tmpTR = new Test_Respondent__c(Id = tr.Id);
            tmpTR.Profile_Update_Processed__c = true;
            trUpdates.add(tmpTR);

        } //END: for(Test_Respondent__c tr: scope)

        //4. Update Contacts/Households
        if(contactUpdates.size() > 0) {
            update contactUpdates.values();
        }
        if(hhUpdates.size() > 0) {
            update hhUpdates.values();
        }

        //FINAL. Check the Profile_Update_Processed__c checkbox on the TR record
        if(trUpdates.size() > 0) {
            update trUpdates;
        }
    }

    global void finish(Database.BatchableContext BC) 
    {
    	//do Nothing
    }

    private sObject processKeyValue(Profile_Update__mdt pu, sObject tmpSO, String sValue) {
        System.debug('DC: pu: ' + pu);
        System.debug('DC: tmpSO: ' + tmpSO);
        System.debug('DC: sValue: ' + sValue);

        if(tmpSO != null) {
            if(pu.Salesforce_Field_Type__c == 'Boolean') {
                tmpSO.put(pu.Salesforce_Field_API_Name__c, Boolean.valueOf(sValue));
            } else if(pu.Salesforce_Field_Type__c == 'Date') {
                Date dt = Date.parse(sValue);
                tmpSO.put(pu.Salesforce_Field_API_Name__c,dt);
            } else if(pu.Salesforce_Field_Type__c == 'DateTime') {
                //sValue example = 09/15/2022 04:11
                //Datetime dtime = (DateTime)JSON.deserialize('"' + sValue + '"', DateTime.class);
                //DateTime dtime = DateTime.parse(sValue);
                //DateTime dtime = Datetime.valueOf(sValue);
                //DateTime dtime = (DateTime) JSON.deserialize(JSON.serialize('"' + sValue + '"'), DateTime.class);
                //DateTime dtime = (DateTime) JSON.deserialize(JSON.serialize(sValue), DateTime.class);

                try {
                    Integer sMonth = Integer.valueOf(sValue.substring(0,2));
                    Integer sDay = Integer.valueOf(sValue.substring(3,5));
                    Integer sYear = Integer.valueOf(sValue.substring(6,10));
                    Integer sHour = Integer.valueOf(sValue.substring(11,13));
                    Integer sMinute = Integer.valueOf(sValue.substring(14,16));
                    DateTime dtime = DateTime.newInstance(sYear, sMonth, sDay, sHour, sMinute, 0);

                    tmpSO.put(pu.Salesforce_Field_API_Name__c,dtime);
                } catch (Exception e) {
                    //This makes the assumption that all the datetimes are in the same format and they might not be.
                }

            } else if(pu.Salesforce_Field_Type__c == 'Number') {
                tmpSO.put(pu.Salesforce_Field_API_Name__c, Decimal.valueOf(sValue));
            } else if (pu.Salesforce_Field_Type__c == 'Multi-Picklist') {
                String tmpMPValue;
                tmpMPValue = fieldMultiPicklistMap.get(pu.Salesforce_Object__c + '-' + pu.Salesforce_Field_API_Name__c);
                if(tmpMPValue == null) {
                    tmpMPValue = '';
                }
                tmpMPValue += sValue + ';';
                fieldMultiPicklistMap.put(pu.Salesforce_Object__c + '-' + pu.Salesforce_Field_API_Name__c, tmpMPValue);
                tmpSO.put(pu.Salesforce_Field_API_Name__c, tmpMPValue);
            } else {
                //Treat it like a string.
                tmpSO.put(pu.Salesforce_Field_API_Name__c, sValue);
            }
        }
        return tmpSO;
    }

    public class hScreenerResults {
        public String key {get;set;}
        public String value {get;set;}
    }
}