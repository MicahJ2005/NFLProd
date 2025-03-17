public with sharing class HostToolBulkController {
/**
*   {Purpose}  �  TODO:  Provide Purpose
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name                    Description
*   20141018    Andy Boettcher DCS      Created
*   =============================================================================
*/

    ///////////////////////////
    // Constructors
    ///////////////////////////
    public HostToolBulkController() {}  

    ///////////////////////////
    // GET / SET
    ///////////////////////////
    @RemoteAction
    public static String testedStatusOptions() {

        List<String> lstStatus = new List<String>();
        for(String str : UtilityMethods.getValuesForPicklist('Test_Respondent__c', 'Tested_Status__c')) {
            lstStatus.add(str);
        }

        return JSON.serialize(lstStatus);

    }

    @RemoteAction
    public static Master_Test__c mtFieldSet(Id masterTestId) {
        String strQuery = 'SELECT ';
        for(Schema.FieldSetMember fsm : SObjectType.Master_Test__c.FieldSets.HostToolView.getFields()) {
            strQuery+= fsm.getFieldPath() + ', ';
        }
        strQuery+= 'Id FROM Master_Test__c WHERE Id = :masterTestId';

        return (Master_Test__c)Database.query(strQuery);
    }

    @RemoteAction
    public static List<Master_Test__c> lstProjects() {
        return [SELECT Id, Opportunity_Name__c 
                    FROM Master_Test__c 
                    WHERE Opportunity_Name__c != NULL 
                        AND Opportunity_Name__c != ''
                        AND IsOpportunityInvoiced__c = false
                    ORDER BY Project_Number__c ASC];
    }

    @RemoteAction
    public static List<String> lstViewTypes() {
        List<String> lstTemp = new List<String>();
        lstTemp.add('Session View');
        lstTemp.add('List View');
        return lstTemp;
    }

    @RemoteAction
    public static List<Session__c> lstSessions(Id masterTestId) {

        return [SELECT Id, Name, Testing_Location__c, Testing_Location__r.Name, Session_Length__c, Linked_Session__c,
                        Related_Test__r.Name
                    FROM Session__c
                    WHERE Related_Test__c = :masterTestId
                    ORDER BY Session_Start__c];
    }

    @RemoteAction
    public static Map<String, Integer> trackerStats(Id masterTestId) {

        // Initialize Status Map
        Map<String, Integer> mapStatusCount = new Map<String, Integer>();
        for(String str : UtilityMethods.getValuesForPicklist('Test_Respondent__c', 'Tested_Status__c')) {
            mapStatusCount.put(str, 0);
        }

        // Pull Test-wide Values
        for(AggregateResult ar : [SELECT Tested_Status__c, Count(Id) RecCount FROM Test_Respondent__c 
                                    WHERE Master_Test__c = :masterTestId 
                                        AND Respondent_Status__c = 'Scheduled'
                                        AND Respondent__c != null
                                    GROUP BY Tested_Status__c]) {
            mapStatusCount.put((String)ar.get('Tested_Status__c'), (Integer)ar.get('RecCount'));
        }

        return mapStatusCount;

    }

    @RemoteAction
    public static List<hClsSession> fillRespondentList(Id masterTestId, Id sessionId, String strViewType, String strRespSearch) {

        // Set Preferences
        UserPreference__c USER_PREFERENCES = UtilityMethods.USER_PREFERENCES();
        USER_PREFERENCES.HostCheckViewMode__c = strViewType;
        upsert USER_PREFERENCES;

        // Get Linked Session Hierarchy
        Map<Id, Map<Id, Decimal>> mapLinkedSessionTRNumbers = new Map<Id, Map<Id, Decimal>>();

        // Fill List
        List<hClsSession> lstFullSessions = new List<hClsSession>();

        // Get all respondents for this Master Test
        Map<Id, Test_Respondent__c> mapRespondents = new Map<Id, Test_Respondent__c>();
        String strRespQuery = 'SELECT Id, Check_Amount__c, Check_Memo__c, Check_Number__c, ';
        strRespQuery+=' Check_Printed_Date__c, Respondent__c, Respondent__r.Name, Respondent__r.FirstName, Respondent__r.LastName, ';
        strRespQuery+=' Respondent__r.PID__c, Donation_Amount_Per_Event__c, Tested_Status__c, ';
        strRespQuery+=' Respondent__r.Age__c, Respondent__r.Gender__c, Respondent_Number__c, ';
        strRespQuery+=' Organization__r.Name, Respondent__r.IVRPhone__c, Session_ID__c, ';
        strRespQuery+=' (SELECT Id, Respondent__c, Respondent__r.Name, Respondent__r.PID__c, Tested_Status__c, ';
        strRespQuery+=' Respondent__r.Age__c, Respondent__r.Gender__c, Respondent_Number__c, Session_ID__c FROM Test_Respondents__r  ';
        strRespQuery+=' WHERE Respondent_Status__c = \'Scheduled\' AND Respondent__c != null) ';
        strRespQuery+=' FROM Test_Respondent__c ';
        strRespQuery+=' WHERE Respondent_Status__c = \'Scheduled\' ';
        strRespQuery+=' AND Respondent__c != null  ';
        strRespQuery+=' AND Pair_Primary__c = null' ;

        if(sessionId == null || strRespSearch != '') { 
            strRespQuery+= ' AND Master_Test__c = :masterTestId ';
        } else {
            strRespQuery+= ' AND Session_ID__c = :sessionId ';
        }

        for(Test_Respondent__c tr : Database.query(strRespQuery)) {
            mapRespondents.put(tr.Id, tr);
        }

        System.Debug(mapRespondents);

        // HANDLE PAIRS
        Map<Id, List<Test_Respondent__c>> mapPairs = new Map<Id, List<Test_Respondent__c>>();
        for(Test_Respondent__c tr : [SELECT Id, Check_Amount__c, Check_Memo__c, Check_Number__c,
                                        Check_Printed_Date__c, Respondent__c, Respondent__r.Name, Respondent__r.FirstName, Respondent__r.LastName,
                                        Respondent__r.PID__c, Donation_Amount_Per_Event__c, Tested_Status__c,
                                        Respondent__r.Age__c, Respondent__r.Gender__c, Respondent_Number__c,
                                        Organization__r.Name, Respondent__r.IVRPhone__c, Pair_Primary__c
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
        Map<Id, List<hClsQuota>> mapRespondentQuotas = new Map<Id, List<hClsQuota>>();

        // Spin through all Respondents
        for(Test_Respondent__c tr : [SELECT Screener_Results__c FROM Test_Respondent__c WHERE Id IN :mapRespondents.keyset()]) {

            List<hClsQuota> lstConditions = new List<hClsQuota>();

            // Put all in list first
            List<hClsQuota> lstAll = new List<hClsQuota>();
            if(tr.Screener_Results__c != null) {
                lstAll = (List<hClsQuota>)JSON.deserialize(tr.Screener_Results__c, List<hClsQuota>.class);
                for(hClsQuota clsQ : lstAll) {
                    if(clsQ.key.indexOf('conditions') >= 0 && clsQ.key.indexOf('conditionsIGNORE') == 0) {
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


        // Pull all ContactIds in for HCIds
        Set<Id> setContactIds = new Set<Id>();
        for(Test_Respondent__c tr : mapRespondents.values()) {
            setContactIds.add(tr.Respondent__c);
        }

        // Pull all household info
        Map<Id, Household_Contact__c> mapHouseholds = new Map<Id, Household_Contact__c>();
        for(Household_Contact__c hc : [SELECT Contact__c, Household__r.MailingStreet__c, Household__r.MailingStreet2__c, 
                                            Household__r.MailingState__c, Household__r.MailingPostalCode__c, Household__r.MailingCity__c,
                                            Household__c
                                            FROM Household_Contact__c WHERE Contact__c IN :setContactIds]) {
            mapHouseholds.put(hc.Contact__c, hc);
        }

        // Get all Sessions for this MT
        List<Session__c> lstSessions;

        String strQuery = 'SELECT ';
        for(Schema.FieldSetMember fsm : SObjectType.Session__c.FieldSets.Quick_Display.getFields()) {
            strQuery+= fsm.getFieldPath() + ', ';
        }
        strQuery+= 'Related_Test__r.Beacon_Condition_Instructions__c, Linked_Session__r.Name, Testing_Location__r.Name, Id, Name, (SELECT Id FROM Session_Quotas__r) FROM Session__c ';


        if(sessionId == null || strRespSearch != '') { 
            strQuery+= ' WHERE Related_Test__c = :masterTestId ';
        } else {
            strQuery+= ' WHERE Id = :sessionId ';
        }

        strQuery+= ' ORDER BY Session_Start__c ASC';

        lstSessions = Database.query(strQuery);

        ////////////////////////////
        // List View
        ////////////////////////////
        if(strViewType == 'List View') {

            Map<Id, Session_Quota__c> mapSQIDs = new Map<Id, Session_Quota__c>();
            String strSQIDQuery = 'SELECT Id FROM Session_Quota__c WHERE ';
            if(sessionId == null || strRespSearch != '') { 
                strSQIDQuery+= ' Related_Session__r.Related_Test__c = :masterTestId ';
            } else {
                strSQIDQuery+= ' Related_Session__c = :sessionId ';
            }

            for(Session_Quota__c sq : (List<Session_Quota__c>)Database.Query(strSQIDQuery)) {
                mapSQIDs.put(sq.Id, sq);
            }

            // Query for (TODO - get out of loop) Respondents in SQs
            Map<Id, Test_Respondent_Quota__c> mapTRQRespIds = new Map<Id, Test_Respondent_Quota__c>();
            for(Test_Respondent_Quota__c trq : [SELECT Id, Test_Respondent__c, Test_Respondent__r.Respondent__c, 
                                                    Session_Quota__r.Related_Session__r.Name,
                                                    Session_Quota__r.Related_Session__c   
                                                    FROM Test_Respondent_Quota__c
                                                    WHERE IsScheduled__c = TRUE
                                                        AND IsTrackingQuota__c = FALSE 
                                                        AND Test_Respondent__r.Respondent_Status__c = 'Scheduled'
                                                        AND Session_Quota__c IN :mapSQIDs.keySet()
                                                        AND Test_Respondent__r.Respondent__c != null
                                                        AND Test_Respondent__r.Pair_Primary__c = null
                                                    ORDER BY Test_Respondent__r.Respondent__r.Lastname, 
                                                        Test_Respondent__r.Respondent__r.FirstName]) {
                
                mapTRQRespIds.put(trq.Test_Respondent__c, trq);
            }

            List<hClsRespondent> lstTRTemp = new List<hClsRespondent>();
            for(Id idR : mapTRQRespIds.keyset()) {
                if(strRespSearch != '') {
                    if(mapRespondents.get(idR).Respondent__r.Name.toLowerCase().indexOf(strRespSearch.toLowerCase()) >= 0 ||
                        mapRespondents.get(idR).Respondent__r.PID__c == strRespSearch) {
                        lstTRTemp.add(new hClsRespondent(
                            mapRespondents.get(idR), 
                            mapHouseholds.get(mapTRQRespIds.get(idR).Test_Respondent__r.Respondent__c), 
                            mapTRQRespIds.get(idR),
                            mapPairs.get(idR),
                            mapRespondentQuotas.containsKey(idR)
                        ));
                    }
                } else {
                    lstTRTemp.add(new hClsRespondent(
                        mapRespondents.get(idR), 
                        mapHouseholds.get(mapTRQRespIds.get(idR).Test_Respondent__r.Respondent__c), 
                        mapTRQRespIds.get(idR),
                        mapPairs.get(idR),
                        mapRespondentQuotas.containsKey(idR)
                    )); 
                }
                
            }

            // Add everything to the final list!
            Session__c seNew = new Session__c(Name='List View Session');
            lstFullSessions.add(new hClsSession(seNew, lstTRTemp));

        }
         else {

            // Get Respondents for selected Sessions
            for(Session__c ses : lstSessions) {
                
                // Get all SQs
                Set<Id> setSQIDs = new Set<Id>();
                for(Session_Quota__c sq : ses.Session_Quotas__r) {
                    setSQIDs.add(sq.Id);
                }

                // Query for (TODO - get out of loop) Respondents in SQs
                Map<Id, Test_Respondent_Quota__c> mapTRQRespIds = new Map<Id, Test_Respondent_Quota__c>();
                for(Test_Respondent_Quota__c trq : [SELECT Id, Test_Respondent__c, Test_Respondent__r.Respondent__c, 
                                                    Session_Quota__r.Related_Session__r.Name,
                                                    Session_Quota__r.Related_Session__c  
                                                        FROM Test_Respondent_Quota__c
                                                        WHERE IsScheduled__c = TRUE
                                                            AND IsTrackingQuota__c = FALSE 
                                                            AND Test_Respondent__r.Respondent_Status__c = 'Scheduled'
                                                            AND Session_Quota__c IN :setSQIDs
                                                            AND Test_Respondent__r.Respondent__c != null
                                                            AND Test_Respondent__r.Pair_Primary__c = null
                                                        ORDER BY Test_Respondent__r.Respondent__r.Lastname, 
                                                            Test_Respondent__r.Respondent__r.FirstName]) {
                    
                    mapTRQRespIds.put(trq.Test_Respondent__c, trq);
                }

                List<hClsRespondent> lstTRTemp = new List<hClsRespondent>();
                for(Id idR : mapTRQRespIds.keyset()) {
                    if(strRespSearch != '' && mapRespondents.containsKey(idR)) {
                        if(mapRespondents.get(idR).Respondent__r.Name.toLowerCase().indexOf(strRespSearch.toLowerCase()) >= 0 ||
                            mapRespondents.get(idR).Respondent__r.PID__c == strRespSearch) {
                            lstTRTemp.add(new hClsRespondent(
                                mapRespondents.get(idR), 
                                mapHouseholds.get(mapTRQRespIds.get(idR).Test_Respondent__r.Respondent__c), 
                                mapTRQRespIds.get(idR),
                                mapPairs.get(idR),
                                mapRespondentQuotas.containsKey(idR)
                            ));
                        }
                    } else {

                        lstTRTemp.add(new hClsRespondent(
                            mapRespondents.get(idR), 
                            mapHouseholds.get(mapTRQRespIds.get(idR).Test_Respondent__r.Respondent__c), 
                            mapTRQRespIds.get(idR),
                            mapPairs.get(idR),
                            mapRespondentQuotas.containsKey(idR)
                        )); 
                    }
                    
                }

                // Add everything to the final list!
                lstFullSessions.add(new hClsSession(ses, lstTRTemp));
            }
        }

        ////////////////////////////
        // Status Map
        ////////////////////////////
        //updateTrackerStats();

        return lstFullSessions;

    }

    @RemoteAction
    public static void saveRespondent(Contact passContact, Test_Respondent__c passRespondent, Household__c passHousehold) {
        if(passContact.Id != null) { upsert passContact; }
        if(passRespondent.Id != null) { upsert passRespondent; }
        if(passHousehold.Id != null) { upsert passHousehold; }

        if(passRespondent.Respondent_Number__c != null) {

            //// Handle Linked Sessions
            Test_Respondent__c trCurrent = [
                SELECT Id, Respondent__c, Respondent_Number__c, Session_ID__c 
                FROM Test_Respondent__c 
                WHERE Id = :passRespondent.Id
            ];
            Map<Id, Session__c> mapLinkedSessions = new Map<Id, Session__c>([
                SELECT Id FROM Session__c WHERE Linked_Session__c = :trCurrent.Session_ID__c
            ]);

            List<Test_Respondent__c> lstLinkedSessions = new List<Test_Respondent__c>();

            if(mapLinkedSessions.size() > 0) {
                System.Debug('STARTING LINKED INNER LOGIC');
                lstLinkedSessions = [
                    SELECT Id, Respondent_Number__c FROM Test_Respondent__c 
                        WHERE Respondent__c = :trCurrent.Respondent__c
                            AND Session_ID__c IN :mapLinkedSessions.keyset()
                            AND Respondent_Number__c = null
                ];
            }

            for(Test_Respondent__c tr : lstLinkedSessions) {
                tr.Respondent_Number__c = passRespondent.Respondent_Number__c;
            }

            if(lstLinkedSessions.size() > 0) {
                update lstLinkedSessions;
            }
        }

    }

    @RemoteAction
    public static List<hClsQuota> respondentQuota(Id respondentId) {
        List<hClsQuota> lstTemp = new List<hClsQuota>();
        for(Test_Respondent__c tr : [SELECT Screener_Results__c FROM Test_Respondent__c WHERE Id = :respondentId]) {
            String strJSON = tr.Screener_Results__c;
            if(tr.Screener_Results__c != null) {
                lstTemp = (List<hClsQuota>)JSON.deserialize(tr.Screener_Results__c, List<hClsQuota>.class);
            }
        }
        return lstTemp;
    }

    @RemoteAction
    public static List<Test_Respondent__c> listDOTChecksForTest(Id masterTestId) {
        return [SELECT Id, Check_Number__c, Check_Amount__c 
                    FROM Test_Respondent__c 
                    WHERE Master_Test__c = :masterTestId
                        AND Respondent__c = null];
    }

    @RemoteAction
    public static void updateTRWithDOTCheck(Id passTRDot, Id passTR) {

        Test_Respondent__c trDOT = [SELECT Check_Number__c, Check_Amount__c, Check_Memo__c, Check_Printed_Date__c 
                                    FROM Test_Respondent__c 
                                    WHERE Id = :passTRDot];

        Test_Respondent__c trReal = [SELECT Check_Number__c, Check_Amount__c, Check_Memo__c, Check_Printed_Date__c 
                                    FROM Test_Respondent__c 
                                    WHERE Id = :passTR];

        trReal.Check_Number__c = trDOT.Check_Number__c;
        trReal.Check_Amount__c = trDOT.Check_Amount__c;
        trReal.Check_Memo__c = trDOT.Check_Memo__c;
        trReal.Check_Printed_Date__c = trDOT.Check_Printed_Date__c;

        delete trDOT;
        update trReal;

    }

    ///////////////////////////
    // Inner / Helper Classes
    ///////////////////////////
    public class hClsSession {

        public Session__c ses {get;set;}
        public List<hClsRespondent> lstTR {get;set;}

        public hClsSession(Session__c passSession, List<hClsRespondent> passRL) {
            ses = passSession;
            lstTR = passRL;
        }
    }

    public class hClsRespondent {

        public Test_Respondent__c tr {get;set;}
        public Household_Contact__c hc {get;set;}
        public Test_Respondent_Quota__c trq {get;set;}
        public List<Test_Respondent__c> lstPairs {get;set;}
        public Integer intRowSpan {get;set;}
        public String strPairStyle {get;set;}
        public Boolean bolShowQuota {get;set;}

        public hClsRespondent(Test_Respondent__c passTR, Household_Contact__c passHC, Test_Respondent_Quota__c passTRQ, List<Test_Respondent__c> passPairList, Boolean showQuota) {
            tr = passTR;
            hc = passHC;
            trq = passTRQ;
            bolShowQuota = showQuota;
            lstPairs = new List<Test_Respondent__c>();
            strPairStyle = '';
            if(passPairList != null) {
                lstPairs = passPairList;
                strPairStyle = ' pairCol';
            }
            intRowSpan = lstPairs.size() + 1;
        }

    }

    public class hClsQuota {
        public String key {get;set;}
        public String value {get;set;}
    }

    //public class hClsQuotaKey {
    //  public Id idMQ {get;set;}
    //  public Integer intCount {get;set;}
    //  public Quota__c mq {get;set;}
    //  public hClsQuotaKey(Id passId, Quota__c passMQ) {
    //      idMQ = passId;
    //      mq = passMQ;
    //      intCount = 0;
    //  }
    //}

}