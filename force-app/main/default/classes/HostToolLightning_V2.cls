/**
 * @description       : 
 * @author            : James Loury (Demand Chain)
 * @group             : 
 * @last modified on  : 03-13-2024
 * @last modified by  : Michael Lloyd (Demand Chain)
**/
global with sharing class HostToolLightning_V2 {
	@AuraEnabled
    public static List<Master_Test__c> getMasterTest(){
        return [SELECT Id
                		,Opportunity_Name__c 
				FROM Master_Test__c 
				WHERE Opportunity_Name__c != NULL 
					AND Opportunity_Name__c != ''
                    AND IsOpportunityInvoiced__c = false 
                    //06.01.2020 - Sophia Murphy (Demand Chain)
                    //          Updated to use LAST session start; long running tests were falling off the list.
                    AND Last_Session_Start__c >= Last_Month
                    //AND First_Session_Start__c >= Last_Month
				ORDER BY Opportunity_Name__c ASC];
    }

    @AuraEnabled
    public static List<hClsSession> fillRespondentList(String idSession, String idMasterTest, String strRespSearch, String strViewType) {
        System.debug('idSession: ' + idSession);
        System.debug('idMasterTest: ' + idMasterTest);
        System.debug('strRespSearch: ' + strRespSearch);
        System.debug('strViewType: ' + strViewType);
        Map<String, Integer> mapStatusCount = new Map<String, Integer>();
        Map<Id, hClsQuotaKey> mapQuotaCount = new Map<Id, hClsQuotaKey>();
        Map<Id, List<Test_Respondent__c>> mapPairs = new Map<Id, List<Test_Respondent__c>>();
        Map<Id, List<hClsQuota>> mapRespondentQuotas = new Map<Id, List<hClsQuota>>();
        Map<String, String> mapColorCodes = new Map<String, String>();
        
        for(HostToolColorCoding__c cc:HostToolColorCoding__c.getall().values()){
            mapColorCodes.put(cc.Name, cc.HexColor__c);
        }

        // Get Linked Session Hierarchy
        Map<Id, Map<Id, Decimal>> mapLinkedSessionTRNumbers = new Map<Id, Map<Id, Decimal>>();

        // Fill List
        List<hClsSession> lstFullSessions = new List<hClsSession>();

        Map<Id, Test_Respondent__c> mapRespondents = new Map<Id, Test_Respondent__c>();
        //05.20.2020 - Sophia Murphy  (Demand Chain) - Added VOID
        //01.30.2021 - Sophia Murphy  (Demand Chain) - Added Phone
        String strRespQuery = 'SELECT Id, Session_Date_Old__c, Master_Test__c, Check_Amount__c, Check_Memo__c, Check_Number__c, Void__c, Session_Name__c, Communication__c,';
        strRespQuery+=' Check_Printed_Date__c, Respondent__c, Respondent__r.Name, Respondent__r.FirstName, Respondent__r.LastName, Respondent__r.Site_Notes__c, ';
        strRespQuery+=' Respondent__r.PID__c, Donation_Amount_Per_Event__c, Tested_Status__c, ';
        strRespQuery+=' Respondent__r.Communication__c, Respondent__r.Age__c, Respondent__r.Gender__c, Respondent__r.Phone, Respondent_Number__c, ';
        strRespQuery+=' Organization__r.Name, Respondent__r.IVRPhone__c, Session_ID__c, Respondent__r.W9_Form_Requested__c, ';
        strRespQuery+=' Street_Address__c, Street_Address_2__c, City__c, State__c, Zip__c, ';
        strRespQuery+=' (SELECT Id, Respondent__c, Respondent__r.Name, Respondent__r.PID__c, Tested_Status__c, ';
        strRespQuery+=' Respondent__r.Age__c, Respondent__r.Gender__c, Respondent_Number__c, Session_ID__c FROM Test_Respondents__r  ';
        strRespQuery+=' WHERE Respondent_Status__c = \'Scheduled\' AND Respondent__c != null) ';
        strRespQuery+=' FROM Test_Respondent__c ';
        strRespQuery+=' WHERE Respondent_Status__c = \'Scheduled\' ';
        strRespQuery+=' AND Respondent__c != null  ';
        strRespQuery+=' AND Pair_Primary__c = null' ;

        if(idSession == null || strRespSearch != '') { 
            strRespQuery+= ' AND Master_Test__c = :idMasterTest ';
        } else {
            strRespQuery+= ' AND Session_ID__c = :idSession ';
        }

        for(Test_Respondent__c tr : Database.query(strRespQuery)) {
            mapRespondents.put(tr.Id, tr);
        }

        // HANDLE PAIRS -- 
        mapPairs = new Map<Id, List<Test_Respondent__c>>();
        for(Test_Respondent__c tr : [SELECT Id, Session_Date_Old__c, Master_Test__c, Check_Amount__c, Check_Memo__c, Check_Number__c, Communication__c, Respondent__r.Communication__c, 
                                        Check_Printed_Date__c, Respondent__c, Respondent__r.Name, Respondent__r.FirstName, Respondent__r.LastName,
                                        Respondent__r.PID__c, Donation_Amount_Per_Event__c, Tested_Status__c, Respondent__r.Site_Notes__c,
                                        Respondent__r.Age__c, Respondent__r.Gender__c, Respondent_Number__c,
                                        Organization__r.Name, Respondent__r.IVRPhone__c, Pair_Primary__c, Session_ID__c
                                    FROM Test_Respondent__c
                                    WHERE Pair_Primary__c IN :mapRespondents.keySet()
                                        AND Respondent_Status__c = 'Scheduled'
                                        AND Respondent__c != null]) {
            
            List<Test_Respondent__c> lstTemp = new List<Test_Respondent__c>();
            if(mapPairs.containsKey(tr.Pair_Primary__c)) {
                lstTemp = mapPairs.get(tr.Pair_Primary__c);
            }

            lstTemp.add(tr);
            mapPairs.put(tr.Pair_Primary__c, lstTemp);
        }

        // GET QUOTA INFORMATION
        mapRespondentQuotas = new Map<Id, List<hClsQuota>>();

        //02.13.2024 - Sophia Murphy (Demand Chain)
        //      Changing this to look at the TRQ records; NOT the Screener_Results - because for manually scheduled people
        //      there is nothing in the Screener_Results
        // Spin through all Respondents
        /**for(Test_Respondent__c tr : [SELECT Screener_Results__c FROM Test_Respondent__c WHERE Id IN :mapRespondents.keyset()]) {

            List<hClsQuota> lstConditions = new List<hClsQuota>();

            // Put all in list first
            List<hClsQuota> lstAll = new List<hClsQuota>();
            if(tr.Screener_Results__c != null) {
                lstAll = (List<hClsQuota>)JSON.deserialize(tr.Screener_Results__c, List<hClsQuota>.class);
                for(hClsQuota clsQ : lstAll) {
                    if(clsQ.key.indexOf('conditions') >= 0) {
                        if(clsQ.value =='1'){
                            clsQ.value = 'qualified';
                        }
                        else{
                            clsQ.value = 'not qualified';
                        }
                        lstConditions.add(clsQ);
                    }
                }
            } else {
                hClsQuota clsQ = new hClsQuota();
                clsQ.key = 'No Quota Information';
                clsQ.value = 'No Quota Information';
                lstConditions.add(clsQ);
            }
            
            // Pull out only "conditions"
            mapRespondentQuotas.put(tr.Id, lstConditions);
        }
        */
        //NOTE: This change means that they can now see Quotas for manually scheduled respondents - 
        // but this will only show the QUALIFIED conditions.  
        List<hClsQuota> lstConditions;
        for(Test_Respondent_Quota__c trq : [SELECT Id, Test_Respondent__c, Beacon_Condition__c FROM Test_Respondent_Quota__c  
                                            WHERE Test_Respondent__c IN :mapRespondents.keySet()
                                            AND Beacon_Condition__c != NULL
                                            AND IsScheduled__c = true
                                            AND IsQualified__c = true]) {

            lstConditions = mapRespondentQuotas.get(trq.Test_Respondent__c);
            if(lstConditions == null) {
                lstConditions = new List<hClsQuota>();
            }

            hClsQuota newQuotaCond = new hClsQuota();
            newQuotaCond.key = trq.Beacon_Condition__c;
            newQuotaCond.value = 'qualified';
            lstConditions.add(newQuotaCond);
            mapRespondentQuotas.put(trq.Test_Respondent__c, lstConditions);
        }


        // Pull all ContactIds in for HCIds
        Set<Id> setContactIds = new Set<Id>();
        for(Test_Respondent__c tr : mapRespondents.values()) {
            setContactIds.add(tr.Respondent__c);
        }

        // Get all Sessions for this MT
        List<Session__c> lstSessions;
        String strQuery = 'SELECT Id, Name, Testing_Location__r.Name, Session_Length__c, Recruits_Per_Session__c, Communication__c,';
        strQuery += 'Scheduled_Respondents__c, Test_Type__c, Recruiting_Notes__c, Session_Start__c, Session_End__c, ';
        strQuery += 'Related_Test__r.Communication__c, (SELECT Id FROM Session_Quotas__r) FROM Session__c';
        if(String.isBlank(idSession) || !String.isBlank(strRespSearch)) { 
            strQuery+= ' WHERE Related_Test__c = :idMasterTest ';
        } else {
            strQuery+= ' WHERE Id = :idSession ';
        }
        //update to EXCLUDE "Invalid Sessions"
        strQuery += ' AND Invalid_Session__c = false ';

        lstSessions = Database.query(strQuery);

        // Get Respondents for selected Sessions
        for(Session__c ses : lstSessions) {
            
            // Get all SQs
            Set<Id> setSQIDs = new Set<Id>();
            for(Session_Quota__c sq : ses.Session_Quotas__r) {
                setSQIDs.add(sq.Id);
            }

            // Query for (TODO - get out of loop) Respondents in SQs
            Map<Id, Id> mapTRQRespIds = new Map<Id, Id>();
            for(Test_Respondent_Quota__c trq : [SELECT Id, Test_Respondent__c, Test_Respondent__r.Respondent__c
                                                    FROM Test_Respondent_Quota__c
                                                    WHERE IsScheduled__c = TRUE
                                                        AND IsTrackingQuota__c = FALSE 
                                                        AND Test_Respondent__r.Respondent_Status__c = 'Scheduled'
                                                        AND Session_Quota__c IN :setSQIDs
                                                        AND Test_Respondent__r.Respondent__c != null
                                                        AND Test_Respondent__r.Pair_Primary__c = null
                                                    ORDER BY Test_Respondent__r.Respondent__r.Lastname, 
                                                        Test_Respondent__r.Respondent__r.FirstName]) {
                
                mapTRQRespIds.put(trq.Test_Respondent__c, trq.Test_Respondent__r.Respondent__c);
            }

            List<hClsRespondent> lstTRTemp = new List<hClsRespondent>();
            for(Id idR : mapTRQRespIds.keyset()) {
                String color;
                if(mapRespondents.containsKey(idR)){
                    if(mapRespondents.get(idR).Check_Number__c != null){
                        color = 'GREEN';
                    }
                    else if(mapRespondents.get(idR).Donation_Amount_Per_Event__c != null){
                        if(mapRespondents.get(idR).Check_Number__c == null 
                                && !mapRespondents.get(idR).Donation_Amount_Per_Event__c.startswith('No')){
                            color = 'ORANGE';
                        }
                        else if(mapRespondents.get(idR).Check_Number__c == null 
                                && mapRespondents.get(idR).Donation_Amount_Per_Event__c.startswith('No')){
                            color = 'RED';
                        }
                        color = 'RED';
                    }
                }
                if(!String.isBlank(strRespSearch) && mapRespondents.containsKey(idR)) {
                    if(mapRespondents.get(idR).Respondent__r.Name.toLowerCase().indexOf(strRespSearch.toLowerCase()) >= 0 ||
                        mapRespondents.get(idR).Respondent__r.PID__c == strRespSearch) {
                        lstTRTemp.add(new hClsRespondent(
                            mapRespondents.get(idR), 
                            null,
                            mapPairs.get(idR),
                            //mapRespondentQuotas.containsKey(idR),
                            mapColorCodes.get(mapRespondents.get(idR).Tested_Status__c),
                            color,
                            mapRespondentQuotas.get(idR)
                        ));
                    }
                } else {

                    System.Debug(mapRespondents.get(idR));
                    System.Debug(mapPairs.get(idR));
                    System.Debug(mapRespondentQuotas.containsKey(idR));

                    lstTRTemp.add(new hClsRespondent(
                        mapRespondents.get(idR), 
                        null,
                        mapPairs.get(idR),
                        //mapRespondentQuotas.containsKey(idR),
                        mapColorCodes.get(mapRespondents.get(idR).Tested_Status__c),
                        color,
                        mapRespondentQuotas.get(idR)
                    )); 
                }
                
            }

            // Add everything to the final list!
            lstFullSessions.add(new hClsSession(ses, lstTRTemp));
        }
        return lstFullSessions;
    }

    //Also referenced in "MTRefreshStatsController"
    public static Map<String, Integer> updateTrackerStats_Map(String masterTestId) {
        return updateTrackerStats_Map(masterTestId, null);
    }
    public static Map<String, Integer> updateTrackerStats_Map(String masterTestId, String sessionId) {
        //Note: sessionId can be null - in that case - return stats for the whole test.
        //TODO: Add in logic for the session breakdowns

        System.debug('DC: masterTestId: ' + masterTestId);
        System.debug('DC: sessionId: ' + sessionId);
        Map<String, Integer> mapStatusCount = new Map<String, Integer>();
        Set<String> setTRids = new Set<String>();

        mapStatusCount = new Map<String, Integer>();
        for(String str : UtilityMethods.getValuesForPicklist('Test_Respondent__c', 'Tested_Status__c')) {
            System.debug('str: ' + str);
            mapStatusCount.put(str, 0);
        }
        System.debug('DC: Map before: ' + mapStatusCount);

        List<Test_Respondent__c> trList = new List<Test_Respondent__c>();
        if(sessionId != null) {
            trList = [SELECT Id, Tested_Status__c, Pair_Primary__c FROM Test_Respondent__c WHERE Master_Test__c = :masterTestId AND Session_ID__c = :sessionId];
        } else {
            trList = [SELECT Id, Tested_Status__c, Pair_Primary__c FROM Test_Respondent__c WHERE Master_Test__c =:masterTestId];
        }
        for(Test_Respondent__c tr : trList){
            if(tr.Pair_Primary__c == null){
                if(tr.Tested_Status__c !=  null && mapStatusCount.containsKey(tr.Tested_Status__c)){
                    System.debug('DC: status: ' + tr.Tested_Status__c);
                    System.debug('DC: In if count: ' + mapStatusCount.get(tr.Tested_Status__c));
                     mapStatusCount.put(tr.Tested_Status__c, mapStatusCount.get(tr.Tested_Status__c)+1);
                }
            }
        }
        return mapStatusCount;
    }


    @AuraEnabled
    public static List<String> updateTrackerStats(String masterTestId, String sessionId) {
        System.debug('DC: masterTestId: ' + masterTestId);
        System.debug('DC: sessionId: ' + sessionId);

        Map<String, Integer> statsMap = updateTrackerStats_Map(masterTestId, sessionId);

        List<String> listDB = new List<String>();

        //10.04.2023 - Sophia Murphy (Demand Chain)
        //We only want to show SOME stats in the host tool
        List<String> validStatuses = new List<String>();
        validStatuses.add('Pending');
        validStatuses.add('PSA');
        validStatuses.add('Additional Tested');
        validStatuses.add('No Show');
        validStatuses.add('Tested');
        validStatuses.add('PO/FG - PSA');
        validStatuses.add('In Progress');
        System.debug('DC: validStatuses: ' + validStatuses);

        for(String key : statsMap.keySet())
        {
            System.debug('DC: key: ' + key);
            System.debug('DC: validStatuses.contains(key): ' + validStatuses.contains(key));
            if(validStatuses.contains(key)) {
                String vDisplay;
                vDisplay = key + ': ' + String.valueOf(statsMap.get(key));
                listDB.add(vDisplay);
            }
        }

        return listDB;
    }
    @AuraEnabled
    public static List<QuotaData> updateTestedGoals(String masterTestId) {
        System.debug('DC: masterTestId: ' + masterTestId);
        List<QuotaData> quotaTableData = new List<QuotaData>();

        Map<String, Integer> testedByCondition = new Map<String,Integer>();
        for (AggregateResult aggregate : [SELECT Session_Quota__r.Master_Quota__c, 
                                                MAX(Beacon_Condition__c) maxCondition,
                                                COUNT(Id) testedCount
                                            FROM Test_Respondent_Quota__c
                                            WHERE Test_Respondent__r.Master_Test__c = :masterTestId
                                            AND Test_Respondent__r.Tested_Status__c = 'Tested'
                                            GROUP BY Session_Quota__r.Master_Quota__c]) {

            testedByCondition.put((String) aggregate.get('maxCondition'), (Integer) aggregate.get('testedCount'));                                    
        }


        for (Quota__c quota : [SELECT Id, Beacon_Condition__c, Tested_Goal__c, Seating_Quota__c
                                  FROM Quota__c
                                  WHERE Related_Test__c = :masterTestId]){
            
            QuotaData row = new QuotaData();                       
            row.condition = quota.Beacon_Condition__c ?? '';
            row.goal = quota.Tested_Goal__c ?? 0;
            row.tested = testedByCondition.get(quota.Beacon_Condition__c) ?? 0;   
            row.isFull = row.goal <= row.tested;
            row.rowColor = getRowColor(row.goal, row.tested, quota.Seating_Quota__c);                        

            quotaTableData.add(row);               
        }

        return quotaTableData;
        //Query for all Master Quotas related to this MT or Session
        // and display the Tested Goal
        /*
        List<String> listDB = new List<String>();
        for(Quota__c mq : [SELECT Id, Beacon_Condition__c, Tested_Goal__c FROM Quota__c WHERE Related_Test__c = :masterTestId]) {
            String vDisplay;
            vDisplay = mq.Beacon_Condition__c + ': ' + String.valueOf(mq.Tested_Goal__c);
            listDB.add(vDisplay);
        }

        return listDB;
        */
    }
    @AuraEnabled
    public static List<Test_Respondent__c> listDOTChecksForTest(String masterTestId) {
        return [SELECT Id, Check_Number__c, Check_Amount__c 
                    FROM Test_Respondent__c 
                    WHERE Master_Test__c = :masterTestId
                        AND Respondent__c = null];
    }
    @AuraEnabled
     public static List<Test_Respondent__c> upcomingTest(String respondentID, String sessionId){
        return [SELECT Id
                        ,Name
                        ,Session_Date__c
                        ,Session_Name__c
                        ,Session_Type__c
                    FROM Test_Respondent__c
                    WHERE Respondent__c = :respondentID
                    AND Session_ID__c != :sessionId
                    AND Session_Date__c >= TODAY
                    ORDER BY Session_Date__c];
     }
     @AuraEnabled
     public static String manageUserViewPreference() {
        String strViewType;
        UserPreference__c USER_PREFERENCES = UtilityMethods.USER_PREFERENCES();
        strViewType = USER_PREFERENCES.HostCheckViewMode__c;
        if(strViewType == '' || strViewType == null ) {
            strViewType = 'Session View';
        }
        return strViewType;
    }
    @AuraEnabled
    public static void updateUserViewPreference(String strViewType) { 
        UserPreference__c USER_PREFERENCES = UtilityMethods.USER_PREFERENCES();
            USER_PREFERENCES.HostCheckViewMode__c = strViewType;
            upsert USER_PREFERENCES;
    }
    @AuraEnabled
    public static List<hClsQuota> respondentQuota(Id respondentId) {
        /**List<hClsQuota> lstTemp = new List<hClsQuota>();
        for(Test_Respondent__c tr : [SELECT Screener_Results__c FROM Test_Respondent__c WHERE Id = :respondentId]) {
            String strJSON = tr.Screener_Results__c;
            if(tr.Screener_Results__c != null) {
                lstTemp = (List<hClsQuota>)JSON.deserialize(tr.Screener_Results__c, List<hClsQuota>.class);
            }
        }
        return lstTemp;
        */
        List<hClsQuota> lstConditions = new List<hClsQuota>();
        for(Test_Respondent_Quota__c trq : [SELECT Id, Test_Respondent__c, Beacon_Condition__c FROM Test_Respondent_Quota__c  
                                            WHERE Test_Respondent__c = :respondentId
                                            AND Beacon_Condition__c != NULL
                                            AND IsScheduled__c = true
                                            AND IsQualified__c = true]) {

            
            hClsQuota newQuotaCond = new hClsQuota();
            newQuotaCond.key = trq.Beacon_Condition__c;
            newQuotaCond.value = 'qualified';
            lstConditions.add(newQuotaCond);
        }
        return lstConditions;
    }
    @AuraEnabled
    public static String sendemailMessage(String emailType, String whatId){
        String retMessage;
        String targetObjId = UserInfo.getUserId();
        List<String> lstTo = new List<String>();
        Map<String, HostToolEmailSettings__c> mapEmailSettings = new Map<String, HostToolEmailSettings__c>();
        mapEmailSettings = HostToolEmailSettings__c.getall();
        
        lstTo = mapEmailSettings.get(emailType).To_Email_Addresses__c.split(';');
        //sendTemplatedEmail(String[] toRecipients, String templateApiName, ID targetObjId, Id whatId, ID orgWideEmailId )
        sendTemplatedEmail(lstTo, mapEmailSettings.get(emailType).Email_Template_Id__c, targetObjId, whatId, mapEmailSettings.get(emailType).OrgWideEmailId__c);
        
        retMessage = mapEmailSettings.get(emailType).MessageToDisplay__c;
        return retMessage;
    }
    @AuraEnabled
    public static void sendBadBehaviorMessage(Id masterTestId, String emailBody){
        //get opportunity name from master test
        String opportunityName = [SELECT Id, Opportunity_Name__c FROM Master_Test__c WHERE Id = :masterTestId LIMIT 1]?.Opportunity_Name__c ?? '';
        Id orgWideEmailId = [SELECT Id FROM OrgWideEmailAddress WHERE Address='info@tasteocracy.com']?.Id;

        //get to addresses
        List<String> toAddresses = new List<String>();
        for (Bad_Behavior_Recipient__mdt recipient : [SELECT Email__c FROM Bad_Behavior_Recipient__mdt]) {
            toAddresses.add(recipient.Email__c);
        }

        //send email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(toAddresses);
        email.setSubject('Bad Behavior: ' + opportunityName);
        email.setPlainTextBody(emailBody);
        email.setorgWideEmailAddressId(orgWideEmailId);
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
    }
    @AuraEnabled
    public static List<String> getStatusValues(){
        List<String> lstStr = new List<String>();
        for(String str : UtilityMethods.getValuesForPicklist('Test_Respondent__c', 'Tested_Status__c')) {
            lstStr.add(str);
        }
        System.debug('lstStr: ' + lstStr);
        return lstStr;
    }

    @AuraEnabled
    public static CheckinResponse QuickCheckinRespondent(String trStatus, String trRepNum, Test_Respondent__c tr, List<Test_Respondent__c> children){
        List<Test_Respondent__c> lstTR = new List<Test_Respondent__c>();
        
        if (trStatus == 'Pending') {
            trStatus = 'Tested';
        }
        if (String.isBlank(trRepNum)) {
            List<Integer> existingRespNums = new List<Integer>();
            for (Test_Respondent__c respondent: [SELECT Id, Respondent_Number__c FROM Test_Respondent__c WHERE Master_Test__c  = :tr.Master_Test__c ]) {
                if (respondent.Respondent_Number__c != null) {
                    existingRespNums.add(Integer.valueOf(respondent.Respondent_Number__c));
                }
            }
            trRepNum = String.valueOf(getFirstNonconsecutive(existingRespNums));
        }
        return CheckinRespondent(trStatus, trRepNum, tr.Id, children);
    }

    public static Integer getFirstNonconsecutive(List<Integer> numList) {
        numList.sort();
        Integer repNumInt = 1;
        for (Integer i = 0; i < numList.size(); i++) {
            if(numList[i] != i+1) {
                repNumInt = i+1;
                break;
            } else if (numList.size() == i+1) {
                repNumInt = numList.size() + 1;
            }
        }
        return repNumInt;
    } 

    @AuraEnabled
    public static CheckinResponse CheckinRespondent(String trStatus, String trRepNum, String trID, List<Test_Respondent__c> child){
        String retMessage;
        Integer trNum;
        List<String> lstretMessage = new List<String>();
        List<Test_Respondent__c> lstTR = new List<Test_Respondent__c>();
        List<Test_Respondent__c> lstUpdateTR = new List<Test_Respondent__c>();
        Test_Respondent__c trOld = new Test_Respondent__c();
        Test_Respondent__c tr = new Test_Respondent__c();
        List<Test_Respondent__c> lstchild = new List<Test_Respondent__c>();
        Test_Respondent__c cTest = new Test_Respondent__c();
        Set<Integer> setInt = new Set<Integer>();
        Set<Integer> setChildChecked = new Set<Integer>();
        Boolean boolCheckinAdult = true;

        //initialize CheckinResponse
        CheckinResponse cr = new CheckinResponse();
        cr.status = 'JustSave';
        cr.messages = new List<String>();

        //clear respondent number if status = pending
        if (trStatus == 'Pending') {
            trRepNum = null;
        }

        trOld = [SELECT Id, Session_ID__c, Respondent__c, Master_Test__c, Tested_Status__c FROM Test_Respondent__c WHERE Id = :trID];

        if(!String.isBlank(trRepNum)){
            trNum = Integer.valueOf(trRepNum);
            lstTR = [SELECT Id FROM Test_Respondent__c WHERE Tested_Status__c = :trStatus AND Respondent_Number__c = :trNum and Master_Test__c = :trOld.Master_Test__c];
        }
        if((trStatus == 'tested' || trStatus =='additional' || trStatus =='additional tested') && String.isBlank(trRepNum)){
            cr.status = 'Error';
            cr.messages.add('Respondent Number is Required');
            boolCheckinAdult = false;
        }
        else{
            if(trStatus == 'tested' && lstTR.size()>0){
                cr.status = 'Error';
                cr.messages.add('Respondent Number: ' + trRepNum + ' has already been used with the Status of ' + trStatus);
                boolCheckinAdult = false;
            }
            else{
                if(String.isBlank(trRepNum)) {
                    tr.Tested_Status__c = trStatus;
                    tr.Id = trID;
                    tr.Respondent_Number__c = trNum;
                    update tr;
                    cr.status = 'JustSave';
                    cr.messages.add('Respondent has been saved without a Respondent Number');
                } else {
                    tr.Tested_Status__c = trStatus;
                    tr.Respondent_Number__c = trNum;
                    tr.Id = trID;
                    update tr;
                    cr.status = 'Success';
                    cr.messages.add('The Respondent with number ' + trRepNum + ' has been successfully checked in');
                }
            }
        }
        if(child.size()>0){
            for(Test_Respondent__c cCheck: child){
                setInt.add(Integer.valueOf(cCheck.Respondent_Number__c));
            }
            for(Test_Respondent__c childCheck: [SELECT Respondent_Number__c FROM Test_Respondent__c WHERE Respondent_Number__c in :setInt AND Tested_Status__c = 'Tested']){
                setChildChecked.add(Integer.valueOf(childCheck.Respondent_Number__c));
            }
            for(Test_Respondent__c c: child){
                if((c.Tested_Status__c == 'tested' || c.Tested_Status__c =='additional' || c.Tested_Status__c =='additional tested') && c.Respondent_Number__c == null){
                    cr.status = 'Error';
                    cr.messages.add('The Child Respondent Number is Required');
                }
                else{
                    cTest = c;
                    lstchild.add(cTest);
                    cr.status = 'Success';
                    cr.messages.add('The Respondent with number ' + c.Respondent_Number__c + ' has been successfully checked in');
                }
            }
            if(lstchild.size()>0){
                update lstchild;
            }
        }
        //try{ //removed try/catch and handling system failures in the front-end
            if(boolCheckinAdult){
                /** 12.16.2021 - START NEW LOGIC */
                //Is this a linked session?
                Map<Id, Session__c> mapLinkedSessions = new Map<Id, Session__c>([
                    SELECT Id FROM Session__c WHERE Linked_Session__c = :trOld.Session_ID__c
                ]);
                
                List<Test_Respondent__c> lstLinkedSessions = new List<Test_Respondent__c>();

                if(mapLinkedSessions.size() > 0) {
                    lstLinkedSessions = [
                        SELECT Id, Respondent_Number__c FROM Test_Respondent__c 
                            WHERE Respondent__c = :trOld.Respondent__c
                                AND Session_ID__c IN :mapLinkedSessions.keyset()
                                AND Respondent_Number__c = null
                    ];
                }
    
                for(Test_Respondent__c trThis : lstLinkedSessions) {
                    Test_Respondent__c testR = new Test_Respondent__c();
                        testR.Id = trThis.Id;
                        testR.Respondent_Number__c = trNum;
                    lstUpdateTR.add(testR);
                }

                if(lstUpdateTR.size()>0){
                    update lstUpdateTR;
                }
                /** 12.16.2021 - END NEW LOGIC */


            }
        /*
        } catch(Exception e) {
            retMessage += 'There was an issue with checking the respondent in';
            retStatus = 'Error';
        }
        */

        return cr;
    }  
    @AuraEnabled
    public static String CreateAllergyCase(String cntID){
        String retMessage;
        System.debug('DC: cntID: ' + cntID);
        Task_Queue__c c = new Task_Queue__c();
        c.RecordTypeId = Schema.SObjectType.Task_Queue__c.getRecordTypeInfosByDeveloperName().get('Coordinator_Queue').getRecordTypeId();
        c.Name = 'Respondent notified host of Food Allergy';
        //c.Test_Respondent__c = trID;
        c.Contact_Name__c = cntID;
        c.Description__c = 'Please check Contact record for details on their food allergy.';
        c.Status__c = 'Open';
        try{
            insert c;
            retMessage = 'CS has been notified of the Food Allergy';
        } catch(Exception e) {
            retMessage= 'There was an issue notifing CS of the Food Allergy';
        }
        return retMessage;
    }
    @AuraEnabled
    public static String CreateBadBehaviorCase(String cntID){
        String retMessage;
        System.debug('DC: cntID: ' + cntID);
        Task_Queue__c c = new Task_Queue__c();
        c.RecordTypeId = Schema.SObjectType.Task_Queue__c.getRecordTypeInfosByDeveloperName().get('Coordinator_Queue').getRecordTypeId();
        c.Name = 'Host alert of Bad Behavior';
        //c.Test_Respondent__c = trID;
        c.Contact_Name__c = cntID;
        c.Description__c = 'Please check Contact record for details on their bad behavior.';
        c.Status__c = 'Open';
        try{
            insert c;
            retMessage = 'CS has been notified of the Behavior';
        } catch(Exception e) {
            retMessage= 'There was an issue notifing CS of the Behavior';
        }
        return retMessage;
    }
    @AuraEnabled
    public static List<hClsQuota> getQuotaInfo(String trID){
        /**List<hClsQuota> lstConditions = new List<hClsQuota>();
        Test_Respondent__c tr = [SELECT Screener_Results__c FROM Test_Respondent__c WHERE Id =:trID];
        List<hClsQuota> lstAll = new List<hClsQuota>();
        if(tr.Screener_Results__c != null) {
            lstAll = (List<hClsQuota>)JSON.deserialize(tr.Screener_Results__c, List<hClsQuota>.class);
            for(hClsQuota clsQ : lstAll) {
                if(clsQ.key.indexOf('conditions') >= 0) {
                    if(clsQ.value =='1'){
                            clsQ.value = 'qualified';
                        }
                        else{
                            clsQ.value = 'not qualified';
                        }
                        lstConditions.add(clsQ);
                    }
                }
            } else {
                hClsQuota clsQ = new hClsQuota();
                clsQ.key = 'No Quota Information';
                clsQ.value = 'No Quota Information';
                lstConditions.add(clsQ);
            }
        return lstConditions;
        */
        List<hClsQuota> lstConditions = new List<hClsQuota>();
        for(Test_Respondent_Quota__c trq : [SELECT Id, Test_Respondent__c, Beacon_Condition__c FROM Test_Respondent_Quota__c  
                                            WHERE Test_Respondent__c = :trID
                                            AND Beacon_Condition__c != NULL
                                            AND IsScheduled__c = true
                                            AND IsQualified__c = true]) {

            hClsQuota newQuotaCond = new hClsQuota();
            newQuotaCond.key = trq.Beacon_Condition__c;
            newQuotaCond.value = 'qualified';
            lstConditions.add(newQuotaCond);
        }
        return lstConditions;
    }
    @AuraEnabled
    public static String updateTRWithDOTCheck(String passTRDot, String passTR) {
        System.debug('passTRDot: ' + passTRDot);
        System.debug('passTR: ' + passTR);
        String retMessage;
        Test_Respondent__c trDOT = [SELECT Check_Number__c, Check_Amount__c, Check_Memo__c, 
                                    Check_Printed_Date__c, IsPositivePayTransmitted__c, PositivePayTransmitted__c
                                    FROM Test_Respondent__c 
                                    WHERE Id = :passTRDot];

        Test_Respondent__c trReal = [SELECT Check_Number__c, Check_Amount__c, Check_Memo__c,     
        							Check_Printed_Date__c, IsPositivePayTransmitted__c, PositivePayTransmitted__c 
                                    FROM Test_Respondent__c 
                                    WHERE Id = :passTR];

        trReal.Check_Number__c = trDOT.Check_Number__c;
        trReal.Check_Amount__c = trDOT.Check_Amount__c;
        trReal.Check_Memo__c = trDOT.Check_Memo__c;
        trReal.Check_Printed_Date__c = trDOT.Check_Printed_Date__c;
        trReal.IsPositivePayTransmitted__c = trDOT.IsPositivePayTransmitted__c;
        trReal.PositivePayTransmitted__c = trDOT.PositivePayTransmitted__c;

        try{
            delete trDOT;
            update trReal;
            retMessage = 'DOT Check: '+ trReal.Check_Number__c +' has been Assigned for ' + trReal.Check_Amount__c + ' amount';
        }
        catch (Exception e) {
            retMessage = 'DOT Check was not Assigned';
        }

        return retMessage;
    }
    @AuraEnabled
    public static hClsCommunications getcomms(String masterTestId, String sessionId){
        hClsCommunications hcomm = new hClsCommunications();
        Master_Test__c masterTest = [SELECT Communication__c, Survey_Research_Analyst_Questionnaire__r.Name FROM Master_Test__c WHERE Id = :masterTestId LIMIT 1];
        hcomm.mComm = masterTest?.Communication__c ?? 'No Testing Notes';
        hcomm.surveryResearchAnalystQRE = masterTest?.Survey_Research_Analyst_Questionnaire__r?.Name ?? 'No Research Analyst QRE';
        if(!String.isBlank(sessionId)){
            hcomm.sComm = [SELECT Communication__c FROM Session__c WHERE Id = :sessionId]?.Communication__c ?? 'No Session Notes';
        } else {
            hcomm.sComm = 'To see session notes please select session';
        }
        /*
        if(String.isBlank(mcom)){
            mcom = 'No Testing Notes';
        }
        if(String.isBlank(scom)){
            scom = 'No Session Notes';
        }
        hcomm.mComm = mcom;
        hcomm.sComm = scom;*/
        return hcomm;
    }
    @AuraEnabled
    public static List<Session__c> getPeelOffs(String masterTestId){
        System.debug('masterTestId: ' + masterTestId);
        return [SELECT Id
                        ,Name
                        ,Testing_Location__r.Name
                        ,Session_Length__c
                        ,Session_Start__c
                        ,Session_End__c
                        ,Recruits_Per_Session__c
                        ,Scheduled_Respondents__c
                        ,Recruiting_Notes__c
                    FROM Session__c 
                    WHERE Related_Test__c =:masterTestId 
                        AND Test_Type__c = 'PO - Peel - Offs'
                        AND Invalid_Session__c = false];
    }
    @AuraEnabled
    public static String ScheduledPeelOffs(String masterTestId, String respondentId, String sessionId){
        String retMessage;
        Boolean scheduled = false;
        System.debug('masterTestId: ' + masterTestId);
        System.debug('respondentId: ' + respondentId);
        System.debug('sessionId: ' + sessionId);
        List<Test_Respondent_Quota__c> lstTRQuotas = new List<Test_Respondent_Quota__c>();
        try{
            Test_Respondent__c trNew = new Test_Respondent__c(Master_Test__c=masterTestId, Respondent__c=respondentId);
            insert trNew;
            List<Test_Respondent_Quota__c> lstInsertTRQs = new List<Test_Respondent_Quota__c>();
            for(Session_Quota__c sq : [SELECT Id FROM Session_Quota__c WHERE Related_Session__c = :sessionId AND IsScheduleEnabled__c = true]) {
                Test_Respondent_Quota__c trq = new Test_Respondent_Quota__c();
                trq.Session_Quota__c = sq.Id;
                //trq.Test_Respondent__c = respondentId;
                trq.Test_Respondent__c = trNew.Id;
                trq.IsQualified__c = true;
                trq.IsScheduled__c = true;
                lstInsertTRQs.add(trq);
            }
            System.debug('lstInsertTRQs: ' + lstInsertTRQs.size());
            if(lstInsertTRQs.size() > 0){ 
                insert lstInsertTRQs; 
            }
            Session__c ses = [SELECT Id FROM Session__c WHERE Id = :sessionId];
            System.debug('DC: trNew: ' + trNew);
            System.debug('DC: ses: ' + ses);

            scheduled = MasterTestLibrary.scheduleRespondentForSession(trNew, ses);
            if(scheduled){
                retMessage = 'The respondent has been scheduled';
            }
            else{
                retMessage = 'Sorry but we were unable to schedule the Respondent for this Peel-Off';
            }
            }catch(Exception e){
                System.debug('DC: exception: ' + e.getMessage());
                retMessage = 'Sorry but we were unable to schedule the Respondent for this Peel-Off';
            }
            System.debug('retMessage: ' + retMessage);
        return retMessage;
    }

    public static String getRowColor(Decimal goal, Integer tested, Boolean seatingQuota) {
        String color = 'black';
        if (goal > tested && seatingQuota) {
            color = 'green';
        } else if (goal > tested) {
            color = 'red';
        } 
        return color;
    }

    public static void sendTemplatedEmail(String[] toRecipients, String templateApiName, String targetObjId, String whatId, String orgWideEmailId ) {
        //  templateId   must be ID of an Email template
        //  targetObjId must be a Contact, User, Lead Id -- also used in merge fields of template recipient.xxxx
        //  whatId    must be an SObject that is used in the merge fields of the template relatedTo.xxxx
        //  fromId    if non null, use current user, otherwise, use this ID (most likely an org wide no reply id)
          
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();    
        Id templateId;  
        try {templateId = [select id, name from EmailTemplate where developername = : templateApiName].id;}
        catch (Exception e) {

        }
        email.setToAddresses(toRecipients);
        email.setTargetObjectId(targetObjId);
        email.setWhatId(whatId);
        email.setorgWideEmailAddressId(orgWideEmailId);
        email.setTemplateId(templateId);
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            return;
        }
        catch (EmailException e) {

        }
    }  
    ///////////////////////////
    // Inner / Helper Classes
    ///////////////////////////
    public class hClsSession {
        @AuraEnabled
        public Session__c ses {get;set;}
        @AuraEnabled
        public List<hClsRespondent> lstTR {get;set;}

        public hClsSession(Session__c passSession, List<hClsRespondent> passRL) {
            ses = passSession;
            lstTR = passRL;
        }
    }

    public class hClsRespondent {
        @AuraEnabled
        public Test_Respondent__c tr {get;set;}
        @AuraEnabled
        public Test_Respondent_Quota__c trq {get;set;}
        @AuraEnabled
        public List<Test_Respondent__c> lstPairs {get;set;}
        @AuraEnabled
        public Integer intRowSpan {get;set;}
        @AuraEnabled
        public String strPairStyle {get;set;}
        //@AuraEnabled
        //public Boolean bolShowQuota {get;set;}
        @AuraEnabled
        public String cc {get;set;}
        @AuraEnabled
        public String chkc {get;set;}
        @AuraEnabled
        public List<hClsQuota> lstRespQuotas {get;set;}
        @AuraEnabled
        public Boolean bolQuotasFull {get;set;} //If true, ALL of the quotas assigned to this person are full!

        //public hClsRespondent(Test_Respondent__c passTR, Test_Respondent_Quota__c passTRQ, List<Test_Respondent__c> passPairList, Boolean showQuota, String colorcode, String chkColor) {
        public hClsRespondent(Test_Respondent__c passTR, Test_Respondent_Quota__c passTRQ, List<Test_Respondent__c> passPairList, String colorcode, String chkColor, List<hClsQuota> quotaList) {
            tr = passTR;
            trq = passTRQ;
            //bolShowQuota = showQuota; //What does this do?
            lstRespQuotas = quotaList;
            cc = 'background-color:' + colorcode;
            chkc = 'font-weight: bold; color: '+chkColor;
            lstPairs = new List<Test_Respondent__c>();
            strPairStyle = 'No Pairs';
            if(passPairList != null) {
                lstPairs = passPairList;
                strPairStyle = 'Pair Testing (see Respondent Card)';
            }
            intRowSpan = lstPairs.size() + 1;

            /**
            //Determine if ALL of this respondents quotas are full...
            // if we find ONE that is NOT full - then bolQuotasFull becomes TRUE
            bolQuotasFull = true;
            List<QuotaData> allQuotas = 
            for(hClsQuota clsQ : lstRespQuotas) {

            }
             */

        }

    }

    public class hClsQuota {
        @AuraEnabled
        public String key {get;set;}
        @AuraEnabled
        public String value {get;set;}
    }

    public class hClsQuotaKey {
        @AuraEnabled
        public Id idMQ {get;set;}
        @AuraEnabled
        public Integer intCount {get;set;}
        @AuraEnabled
        public Quota__c mq {get;set;}
        public hClsQuotaKey(Id passId, Quota__c passMQ) {
            idMQ = passId;
            mq = passMQ;
            intCount = 0;
        }
    }
    public class hClsCommunications {
        @AuraEnabled
        public String mComm {get;set;}
        @AuraEnabled
        public String sComm {get;set;}
        @AuraEnabled
        public String surveryResearchAnalystQRE {get;set;}
    }
    public class CheckinResponse {
        @AuraEnabled
        public String status {get;set;}
        @AuraEnabled
        public List<String> messages {get;set;}
    }
    public class QuotaData {
        @AuraEnabled
        public String condition { get; set; }
        @AuraEnabled
        public Decimal goal { get; set; }
        @AuraEnabled
        public Integer tested { get; set; }
        @AuraEnabled
        public Boolean isFull { get; set; }
        @AuraEnabled
        public String rowColor { get; set; }
    }
}