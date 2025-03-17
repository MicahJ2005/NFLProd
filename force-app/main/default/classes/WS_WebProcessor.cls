@RestResource(urlMapping='/actions/*')
global with sharing class WS_WebProcessor {
    
    /**
*   {Purpose}  	-  	REST Webservice for Valtira and other systems to consume
*					Use workbench.developerforce.com/restExplorer.php to test
*					POST - /services/apexrest/actions/{action name}
*
*	{Input}		- 	JSON, strict to wsRequest class
*
*	{Output}	-	JSON, strict from wsResponse class - no other outputs are
*					sent.
*
*   {Contact}   - 	support@demandchainsystems.com
*                 	www.demandchainsystems.com
*                 	612-424-0032                  
*/
    
    /**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name                    Description
*   20140506    Andy Boettcher (DCS)    Created
*   2019.07.22  Sophia Murphy (Demand Chain)
*               Added pollRespondent method
*	2020.01.24	Sophia Murphy (Demand Chain)
*				Update to respondentSignin method, to track app signins
*	2021.04.12	Sophia Murphy (Demand Chain)
*				New method to check respondent access; Case 9693
*	2023.05.18	Sammy Zawahiri (Demand Chain)
*				New confirmTesting method in test respondent object; Case 11496 
*   2024.02.01  Sophia Murphy (Demand Chain)
*               New method for respondentCashOut - called from website when respondent requests a payout
*   =============================================================================
*/
    
    global static RestResponse resp;
    global static wsRequest reqBody;
    global static Boolean bolProcessedAction = false;
    global static String strMessageDetail = '';
    global static List<jsonQuestion> lstMessageExtras = new List<jsonQuestion>();
    
    ///////////////////////////////
    // HTTP ACTIONS
    ///////////////////////////////
    @HttpPost
    global static void actionRouter() {
        
        RestRequest req = RestContext.request;
        resp = RestContext.response;
        resp.statusCode = 200;
        resp.addHeader('Content-Type', 'application/json');
        
        Set<String> setActions = UtilityMethods.ACTIONS_RESTSERVICE();
        
        // Process Request Body
        try {
            reqBody = (wsRequest)JSON.deserializeStrict(RestContext.request.requestBody.toString(), 
                                                        wsRequest.class);
            
            // Double Check envelope
            if(reqBody.overrideCancellation == null) {
                reqBody.overrideCancellation = false;
            }
            
            // Interrogate Actions
            if(reqBody.actionName.length() == 0) {
                String strDetails = 'Actions Supported: ';
                for(String str : setActions) { strDetails += ' ' + str; }
                processResponse(false, 1001, reqBody.actionName, strDetails);
                return;
            }
            
            if(!setActions.contains(reqBody.actionName)) {
                String strDetails = 'Actions Supported: ';
                for(String str : setActions) { strDetails += ' ' + str; }
                processResponse(false, 1001, reqBody.actionName, strDetails);
                return;
            }
            
            // Route Actions
            System.Debug('actionRouter - REQUESTED ACTION = ' + reqBody.actionName);
            
            if(reqBody.actionName == 'householdManage') { householdManage(); }
            if(reqBody.actionName == 'householdRefresh') { householdRefresh(); }
            if(reqBody.actionName == 'householdRefreshDate') { householdRefreshDate(); }
            if(reqBody.actionName == 'householdMemberManage') { householdMemberManage(); }
            if(reqBody.actionName == 'householdMemberRemove') { householdMemberRemove(); }
            if(reqBody.actionName == 'householdMemberRefresh') { householdMemberRefresh(); }
            if(reqBody.actionName == 'screenerCreateStub') { screenerCreateStub(); }
            if(reqBody.actionName == 'screenerAddResults') { screenerAddResults(); }
            if(reqBody.actionName == 'screenerResetSweeper') { screenerResetSweeper(); }
            if(reqBody.actionName == 'respondentSignup') { respondentSignup(); } 
            if(reqBody.actionName == 'respondentSignin') { respondentSignin(); } 
            if(reqBody.actionName == 'respondentManage') { respondentManage(); } 
            if(reqBody.actionName == 'respondentSchedule') { respondentSchedule(); }
            if(reqBody.actionName == 'respondentCancel') { respondentCancel(); }
            if(reqBody.actionName == 'respondentRefresh') { respondentRefresh(); }
            if(reqBody.actionName == 'respondentRefreshDate') { respondentRefreshDate(); }
            if(reqBody.actionName == 'respondentCheck') { respondentCheck(); }
            if(reqBody.actionName == 'testRespondentRefresh') { testRespondentRefresh(); }
            if(reqBody.actionName == 'testExcludedProjects') { testExcludedProjects(); }
            if(reqBody.actionName == 'testRefresh') { testRefresh(); }
            if(reqBody.actionName == 'testRefreshDate') { testRefreshDate(); }
            if(reqBody.actionName == 'testAllOpenRecords') { testAllOpenRecords(); }
            if(reqBody.actionName == 'sessionRefresh') { sessionRefresh(); }
            if(reqBody.actionName == 'fundraisingSignup') { fundraisingSignup(); }
            if(reqBody.actionName == 'pollRespondentCreate') { pollRespondentCreate(); }
            if(reqBody.actionName == 'confirmTesting') { confirmTesting(); }
            if(reqBody.actionName == 'respondentCashOut') { respondentCashOut(); }
            
            if(bolProcessedAction) {
                resp.responseBody = blob.valueOf(JSON.serialize(new wsResponse(true, 0, reqBody.actionName, strMessageDetail)));
            }
            
        } catch(JSONException exJSON) {
            processResponse(false, 1000, null, exJSON.getMessage());
        } catch(Exception ex) {
            processResponse(false, 9999, null, ex.getMessage());
        }
        
    }
    
    ///////////////////////////////
    // Worker Methods
    ///////////////////////////////
    public static void fundraisingSignup() {
        
        // Check Required Data
        if(reqBody.acctFundraising == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        if(reqBody.conFundraisingMain == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        if(reqBody.conFundraisingCheck == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        // Fundraising Org fields:
        // Required fields: Name, Type, Phone
        // Other fields: Status, Tax_ID__c, CorporateStreet__c, CorporateCity__c, CorporateState__c, CorporatePostalCode__c, Primary_Account_Contact__c
        
        Account objAcct = reqBody.acctFundraising;
        objAcct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Fundraising Organization').getRecordTypeId();
        
        insert objAcct;
        
        // Fundraising Org Contact - create and associate to Account (Contact Person)
        Contact objContact = reqBody.conFundraisingMain;
        objContact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Fundraising Organization').getRecordTypeId();
        objContact.AccountId = objAcct.Id;
        objContact.Description = 'Primary Contact for Fundraising Organization';
        insert objContact;
        
        // Fundraising Org Contact - create and associate to Account ()
        Contact objContactCheck = reqBody.conFundraisingCheck;
        objContactCheck.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Fundraising Organization').getRecordTypeId();
        objContactCheck.AccountId = objAcct.Id;
        objContactCheck.Description = 'Check Name Contact for Fundraising Organization';
        insert objContactCheck;
        
        strMessageDetail = objAcct.Id;
        bolProcessedAction = true;
        
    }
    
    public static void respondentSignin() {
        
        // Check Required Data
        if(reqBody.conRespondent == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        Contact conMain = reqBody.conRespondent;
        Set<Id> setHouseholdIds = new Set<Id>();
        Set<Id> setContactIds = new Set<Id>();
        Set<Id> setHouseholdContactIds = new Set<Id>();
        Map<String, String> SQS_QUEUES = UtilityMethods.SQS_QUEUES();
        
        //01.22.2020 - If they are logging in from the APP - isApp comes across as true
        //and we need to log data into “Last Tasteocracy App Login Date” and increment the counter at “Tasteocracy App Logins”
        try {
            Contact tmpC = [SELECT Id, Last_Tasteocracy_App_Login_Date__c, Tasteocracy_App_Logins__c, Last_FPITesters_Login_Date__c, FPITESTERS_Logins__c FROM Contact WHERE Id = :conMain.Id];
            if(reqBody.isApp) {
                //I'm going to query the single contact and then update it.
                //Contact tmpC = [SELECT Id, Last_Tasteocracy_App_Login_Date__c, Tasteocracy_App_Logins__c FROM Contact WHERE Id = :conMain.Id];
                Decimal curCounter = tmpC.Tasteocracy_App_Logins__c;
                if(curCounter == null) {
                    curCounter = 0;
                }
                //tmpC.Last_Tasteocracy_App_Login_Date__c = Date.today();
                //tmpC.Tasteocracy_App_Logins__c = curCounter+1;
                conMain.Last_Tasteocracy_App_Login_Date__c = Date.today();
                conMain.Tasteocracy_App_Logins__c = curCounter+1;
            } else {
                Decimal curCounter = tmpC.FPITESTERS_Logins__c;
                if(curCounter == null) {
                    curCounter = 0;
                }
                //tmpC.Last_FPITesters_Login_Date__c = Date.today();
                //tmpC.FPITESTERS_Logins__c = curCounter+1;
                conMain.Last_FPITesters_Login_Date__c = Date.today();
                conMain.FPITESTERS_Logins__c = curCounter+1;
            }
            //update tmpC;
            update conMain;
        } catch (Exception e) {}
        
        // Get Household Data for main respondent
        for(Household_Contact__c hc : [SELECT Household__c FROM Household_Contact__c WHERE Contact__c = :conMain.Id]) {
            setHouseholdIds.add(hc.Household__c);
        }
        
        // Get all HouseholdContactsIds and ContactIds for all in main Household
        for(Household_Contact__c hc : [SELECT Id, Contact__c FROM Household_Contact__c WHERE Household__c IN :setHouseholdIds]) {
            setContactIds.add(hc.Contact__c);
            setHouseholdContactIds.add(hc.Id);
        }
        
        // Instanciate Bulk Response object and fill with data
        WS_WebProcessor.wsResponseBulk bulkResponse = new WS_WebProcessor.wsResponseBulk();
        String strQueryContact = SQS_QUEUES.get('FPIRespondent') + ' AND Id IN :setContactIds';
        String strQueryHousehold = SQS_QUEUES.get('FPIHousehold') + ' WHERE Id IN :setHouseholdIds';
        String strQueryHouseholdContact = SQS_QUEUES.get('FPIHouseholdContact') + ' WHERE Id IN :setHouseholdContactIds';
        
        bulkResponse.contacts = Database.Query(strQueryContact);
        bulkResponse.households = Database.Query(strQueryHousehold);
        bulkResponse.householdcontacts = Database.Query(strQueryHouseholdContact);
        
        String strResponseBulk = JSON.serialize(bulkResponse);
        
        strMessageDetail = strResponseBulk;
        bolProcessedAction = true;
        
    }
    
    private static void householdManage() {
        // Check Required Data
        if(reqBody.hseHousehold == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        // Set Initial Data and Variables
        Household__c hse = reqBody.hseHousehold;
        
        try{
            
            // Perform Upsert
            upsert hse;
            strMessageDetail = hse.Id;
            
            // Data is good, proceed.
            bolProcessedAction = true;
            
        } catch(Exception ex) {
            processResponse(false, 9999, reqBody.actionName, ex.getMessage());
        }
        
        
    }
    //Sammy Zawahiri: Demand Chain
    public static void confirmTesting() {
        // Check Required Data
        if(reqBody.trRespondent == null || reqBody.trRespondent.Confirmed_Testing__c == null || reqBody.seSession == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        try {
            Test_Respondent__c trContactId = [SELECT Id, Respondent__c, Confirmed_Testing__c FROM Test_Respondent__c WHERE Id = :reqBody.trRespondent.Id LIMIT 1];
            
            // Update the Confirmed_Testing__c field with the value provided in the request
            if(reqBody.trRespondent.Confirmed_Testing__c.equals('Yes') || reqBody.trRespondent.Confirmed_Testing__c.equals('No')) {
                trContactId.Confirmed_Testing__c = reqBody.trRespondent.Confirmed_Testing__c;
                update trContactId;
                strMessageDetail = 'Field Updated';
                bolProcessedAction = true;
                
                // If the value provided in the request is 'No', call MasterTestLibrary.cancelRespondentFromSession()
                if(reqBody.trRespondent.Confirmed_Testing__c.equals('No')) {
                    MasterTestLibrary.cancelRespondentFromSession(reqBody.trRespondent, reqBody.seSession);
                }
            } else if(reqBody.trRespondent.Confirmed_Testing__c.equals('')) {
                // If the value is empty, update the field but don't call MasterTestLibrary.cancelRespondentFromSession()
                trContactId.Confirmed_Testing__c = reqBody.trRespondent.Confirmed_Testing__c;
                update trContactId;
                strMessageDetail = 'Field Updated';
                bolProcessedAction = true;
            } else {
                // If the value provided in the request is not 'Yes', 'No', or '', return an error
                processResponse(false, 9999, reqBody.actionName, 'Invalid value for Confirmed Testing');
            }
        } catch(Exception ex) {
            processResponse(false, 9999, reqBody.actionName, ex.getMessage());
        }
    }
    
    private static void householdRefreshDate() {
        
        // Check Required Data
        if(reqBody.hseHousehold == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        // Poll and update all Households
        Map<Id, Household__c> mapHouseholds = new Map<Id, Household__c>([SELECT Id FROM Household__c WHERE LastModifiedDate > :reqBody.hseHousehold.LastModifiedDate]);
        if(mapHouseholds.size() > 0) { update mapHouseholds.values(); }
        
        List<Household_Contact__c> lstContacts = [SELECT Id FROM Household_Contact__c WHERE Household__c IN :mapHouseholds.keyset()];
        if(lstContacts.size() > 0) { update lstContacts; }
        
        
        // Data is good, proceed.
        strMessageDetail = 'Refresh will be pushed via SAPI';
        bolProcessedAction = true;
    } 
    
    private static void householdRefresh() {
        
        // Check Required Data
        if(reqBody.hseHousehold == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        try{
            
            // Set Initial Data and Variables
            Household__c hse = new Household__c(Id=reqBody.hseHousehold.Id);
            
            // Perform Upsert of Household
            update hse;
            
            List<Household_Contact__c> lstContacts = [SELECT Id FROM Household_Contact__c WHERE Household__c = :reqBody.hseHousehold.Id];
            update lstContacts;
            
            // Data is good, proceed.
            strMessageDetail = 'Refresh will be pushed via SAPI';
            bolProcessedAction = true;
            
        } catch(Exception ex) {
            processResponse(false, 9999, reqBody.actionName, ex.getMessage());
        }
    }
    
    private static void householdMemberManage() {
        
        // Check Required Data
        if(reqBody.hcMember == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        try{
            
            // Set Initial Data and Variables
            Household_Contact__c hhm = reqBody.hcMember;
            
            // Perform Upsert
            upsert hhm;
            strMessageDetail = hhm.Id;
            
            // Data is good, proceed.
            bolProcessedAction = true;
            
        } catch(Exception ex) {
            processResponse(false, 9999, reqBody.actionName, ex.getMessage());
        }
    }
    
    private static void householdMemberRemove() {
        
        // Check Required Data
        if(reqBody.hcMember == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        try{
            
            // Set Initial Data and Variables
            Household_Contact__c hhm = reqBody.hcMember;
            
            // Perform Upsert
            delete hhm;
            strMessageDetail = 'Record Deleted';
            
            // Data is good, proceed.
            bolProcessedAction = true;
            
        } catch(Exception ex) {
            processResponse(false, 9999, reqBody.actionName, ex.getMessage());
        }
    }
    
    private static void householdMemberRefresh() {
        
        // Check Required Data
        if(reqBody.hcMember == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        try{
            
            // Set Initial Data and Variables
            Household_Contact__c hhm = new Household_Contact__c(Id=reqBody.hcMember.Id);
            
            // Perform Upsert
            update hhm;
            
            // Data is good, proceed.
            strMessageDetail = 'Refresh will be pushed via SAPI';
            bolProcessedAction = true;
            
        } catch(Exception ex) {
            processResponse(false, 9999, reqBody.actionName, ex.getMessage());
        }
    }
    
    private static void screenerCreateStub() {
        
        // Check Required Data
        if(reqBody.conRespondent == null || reqBody.mtTest == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        try{
            
            UtilityMethods.bolPreventContactRollup = true;
            
            // Perform check to ensure that duplicates aren't created!
            List<Test_Respondent__c> lstExistingTRs = [
                SELECT Id 
                FROM Test_Respondent__c 
                WHERE 
                Respondent__c = :reqBody.conRespondent.Id
                AND Master_Test__c = :reqBody.mtTest.Id
                LIMIT 1
            ];
            
            // Create or Return Test Respondent Record
            if(lstExistingTRs.size() > 0) {
                
                for(Test_Respondent__c tr : lstExistingTRs) {
                    strMessageDetail = tr.Id;
                }
                
            } else {
                
                // Set Initial Data and Variables
                Test_Respondent__c trNew = new Test_Respondent__c(Master_Test__c=reqBody.mtTest.Id,Respondent__c=reqBody.conRespondent.Id);
                insert trNew;
                
                // Perform Upsert
                strMessageDetail = trNew.Id;
                
            }
            
            // Seed TRQ records based on SQs.
            List<Test_Respondent_Quota__c> lstInsertTRQs = new List<Test_Respondent_Quota__c>();
            for(Session_Quota__c sq : [SELECT Id FROM Session_Quota__c WHERE Related_Session__r.Related_Test__c = :reqBody.mtTest.Id AND IsScheduleEnabled__c = true]) {
                Test_Respondent_Quota__c trq = new Test_Respondent_Quota__c();
                trq.Session_Quota__c = sq.Id;
                trq.Test_Respondent__c = strMessageDetail;
                trq.IsQualified__c = false;
                trq.IsScheduled__c = false;
                lstInsertTRQs.add(trq);
            }
            
            if(lstInsertTRQs.size() > 0) { insert lstInsertTRQs; }
            
            // Set Number of inserted TRQs
            lstMessageExtras.add(new jsonQuestion('insertedTRQs', string.valueOf(lstInsertTRQs.size())));
            
            // Data is good, proceed.
            bolProcessedAction = true;
            
        } catch(Exception ex) {
            processResponse(false, 9999, reqBody.actionName, ex.getMessage());
        }
        
    }
    
    private static void screenerResetSweeper() {
        // Check Required Data
        if(reqBody.trRespondent == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        Test_Respondent__c trContactId = [SELECT Id, DecipherSweepCount__c FROM Test_Respondent__c WHERE Id = :reqBody.trRespondent.Id LIMIT 1];
        
        trContactId.DecipherSweepCount__c = 0;
        update trContactId;
        
        // Data is good, proceed.
        bolProcessedAction = true;
        
        return;
    }
    
    private static void screenerAddResults() {
        // Check Required Data
        if(reqBody.trRespondent == null || reqBody.jsonBulkData == null || reqBody.mtTest == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        try {
            
            UtilityMethods.bolPreventContactRollup = true;
            
            // ADDED 20150306 - CHECK IF BEACON RESULTS EXIST, IF SO TERMINATE PROCESSING
            // Get Linked Contact record from Test Respondent
            Test_Respondent__c trContactId = [SELECT Id, Respondent__c, Screener_Results__c FROM Test_Respondent__c WHERE Id = :reqBody.trRespondent.Id LIMIT 1];
            if(trContactId.Screener_Results__c != null && trContactId.Screener_Results__c != '[]') {
                System.Debug('screenerAddResults - FOUND EXISTING BEACON RESULTS, NOT REIMPORTING BEACON DATA');
                strMessageDetail = '0';  // Return -1 qualified results back to FPITesters
                bolProcessedAction = true;
                return;
            } 
            
            // ADDED 20150306 - Get existing TRQs for the TR
            Map<Id, Test_Respondent_Quota__c> mapExistingTRQs = new Map<Id, Test_Respondent_Quota__c>();
            for(Test_Respondent_Quota__c trq : [SELECT Id, Session_Quota__c, IsQualified__c FROM Test_Respondent_Quota__c WHERE Test_Respondent__c = :reqBody.trRespondent.Id]) {
                mapExistingTRQs.put(trq.Session_Quota__c, trq);
            }
            
            // Parse out incoming Beacon JSON array
            Map<String, Quota__c> mapBeaconQuotas = new Map<String, Quota__c>();
            for(Quota__c mq : [SELECT Id, Beacon_Condition__c, IsScheduleEnabled__c, Screener_Update_Field__c,
                               Screener_Update_Value__c 
                               FROM Quota__c WHERE Related_Test__c = :reqBody.mtTest.Id]) {
                                   mapBeaconQuotas.put(mq.Beacon_Condition__c, mq);
                               }
            Map<Id, List<Session_Quota__c>> mapSessionQuotas = new Map<Id, List<Session_Quota__c>>();
            
            for(Quota__c mq : [SELECT Id, (SELECT Id FROM Session_Quotas__r) FROM Quota__c WHERE Related_Test__r.Last_Session_Start__c >= :System.Today()]) {
                mapSessionQuotas.put(mq.Id,mq.Session_Quotas__r);
            }
            
            // Set default Test Respondent - Respondent Status
            String strRespondentStatus = 'Started';
            Boolean bolUpdateTRStatus = false;
            Boolean bolOverrideAllProcessing = false;
            Integer intQualifiedTRQs = 0;
            
            List<Test_Respondent_Quota__c> lstTRQInsert = new List<Test_Respondent_Quota__c>();
            for(jsonQuestion jq : reqBody.jsonBulkData) {
                //System.Debug('Processing k-v pair of ' + jq.key + ' - ' + jq.value);
                
                // Check for Beacon "status" to update Test Respondent - Respondent Status
                if(jq.key == 'status') {
                    if(jq.value == '1') { bolUpdateTRStatus = true; strRespondentStatus = 'Disqualified'; }
                    if(jq.value == '2') { bolUpdateTRStatus = true; strRespondentStatus = 'Over Quota'; }
                    if(jq.value == '3') { bolUpdateTRStatus = true; strRespondentStatus = 'Qualified'; }
                    if(jq.value == '4') { bolOverrideAllProcessing = true; }
                }
                
                if(mapBeaconQuotas.containsKey(jq.key)) {
                    if(mapBeaconQuotas.get(jq.Key).IsScheduleEnabled__c) {
                        // Beacon Response is in MQ and is designated as a schedulable condition!
                        Boolean bolQualified = false;
                        if(jq.value == '1') { bolQualified = true;}
                        
                        //error here...
                        for(Session_Quota__c sq : mapSessionQuotas.get(mapBeaconQuotas.get(jq.key).Id)) {
                            if(mapExistingTRQs.containsKey(sq.Id)) {
                                mapExistingTRQs.get(sq.Id).IsQualified__c = bolQualified;
                            } else {
                                Test_Respondent_Quota__c trq = new Test_Respondent_Quota__c();
                                trq.Session_Quota__c = sq.Id;
                                trq.Test_Respondent__c = reqBody.trRespondent.Id;
                                trq.IsQualified__c = bolQualified;
                                trq.IsScheduled__c = false;
                                lstTRQInsert.add(trq);
                            }
                            
                            if(bolQualified) { intQualifiedTRQs++; }
                        }
                    } else {
                        // Beacon Response is in MQ but is an ancillary contact update
                        Contact conUpdate = new Contact(Id=trContactId.Respondent__c);
                        String strFieldName = String.valueOf(mapBeaconQuotas.get(jq.Key).Screener_Update_Field__c).toLowerCase();
                        // Make sure that the Screener_Update_Field Exists!
                        Set<String> objectFields = Schema.SObjectType.Contact.fields.getMap().keySet();
                        if(objectFields.contains(strFieldName)) {
                            // Determine what to put in the field
                            if(mapBeaconQuotas.get(jq.Key).Screener_Update_Value__c != null) {
                                conUpdate.put(strFieldName, mapBeaconQuotas.get(jq.Key).Screener_Update_Value__c);
                            } else {
                                conUpdate.put(strFieldName, jq.value);
                            }
                            
                            update conUpdate;
                        }
                    }
                }
            }
            
            // If all business rules are still OK, proceed - otherwise override all processing and return SUCCESS
            if(!bolOverrideAllProcessing) {
                
                // Insert Screener Response in to TR
                Test_Respondent__c trUpdate = reqBody.trRespondent;
                trUpdate.Screener_Results__c = JSON.serialize(reqBody.jsonBulkData);
                if(bolUpdateTRStatus) { 
                    trUpdate.Screener_Qualification_Result__c = strRespondentStatus;
                    trUpdate.Respondent_Status__c = strRespondentStatus; 
                }
                trUpdate.Tested_Status__c = 'Screened';
                
                System.Debug('UPDATING TR to ' + trUpdate);
                
                update trUpdate;
                
                // Insert TRQs
                if(lstTRQInsert.size() > 0) { insert lstTRQInsert; }
                
                // Update Existing TRQs
                if(mapExistingTRQs.size() > 0) { update mapExistingTRQs.values(); }
                
                // Data is good, proceed.
                // strMessageDetail = String.valueOf(lstTRQInsert.size());  // Replaced by count of Qualified 20150306 AAB
                strMessageDetail = String.valueOf(intQualifiedTRQs);
                
                // Set Number of inserted TRQs
                lstMessageExtras.add(new jsonQuestion('insertedTRQs', String.valueOf(lstTRQInsert.size())));
                lstMessageExtras.add(new jsonQuestion('updatedTRQs', String.valueOf(mapExistingTRQs.size())));
                lstMessageExtras.add(new jsonQuestion('qualifiedTRQs', String.valueOf(strMessageDetail)));
                
                bolProcessedAction = true;
                
            } else {
                
                // Set Number of inserted TRQs
                lstMessageExtras.add(new jsonQuestion('insertedTRQs', '0'));
                lstMessageExtras.add(new jsonQuestion('updatedTRQs', '0'));
                lstMessageExtras.add(new jsonQuestion('qualifiedTRQs', '0'));
                
                strMessageDetail = 'There was a respondent result from Beacon that has resulted in the halting of any TR/TRQ processing - this is not an error.';
                bolProcessedAction = true;
                
            }
            
        } catch(Exception ex) {
            
            String strExceptionMessage = string.valueOf(ex.getLineNumber()) + ' - ' + string.valueOf(ex.getMessage());
            processResponse(false, 9999, reqBody.actionName, strExceptionMessage);
        }
    }
    
    private static void respondentSignup() {
        
        // Check Required Data
        if(reqBody.conRespondent == null || reqBody.hseHousehold == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        try{
            
            // Insert Respondent First
            respondentManage();
            Id idRespondent = strMessageDetail;
            
            // Create Household
            UtilityMethods.bolTriggerSignupFlag = true;
            householdManage();
            UtilityMethods.bolTriggerSignupFlag = false;
            Id idHousehold = strMessageDetail;
            
            // Define Head of Household 20141030 AAB Add per Becky Miller
            Household__c hseHOH = new Household__c(Id=idHousehold, Head_of_Household__c=idRespondent);
            update hseHOH;
            
            // Associate Respondent to Household
            Household_Contact__c hhc = new Household_Contact__c();
            hhc.Contact__c = idRespondent;
            hhc.Household__c = idHousehold;
            
            upsert hhc;
            strMessageDetail = idRespondent;
            
            // Data is good, proceed.
            bolProcessedAction = true;
            
            
        } catch(Exception ex) {
            processResponse(false, 9999, reqBody.actionName, ex.getMessage());
        }
        
    }
    
    private static void respondentManage() {
        
        // Check Required Data
        if(reqBody.conRespondent == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        try{
            
            if(reqBody.conRespondent.BirthDate == null) {
                processResponse(false, 1002, reqBody.actionName, 'Birthdate must be provided!');
                return;
            }
            
            // Set Initial Data and Variables
            Contact con = reqBody.conRespondent;
            Map<String, String> mapAppSettings = UtilityMethods.APP_SETTINGS();
            
            // Ensure that base data is intact
            con.RecordTypeId = mapAppSettings.get('RT_ContactRespondentAdult');
            con.AccountId = mapAppSettings.get('ID_RespondentAccount');
            
            // Determine RecordType
            Integer intAge = integer.valueOf(con.BirthDate.daysBetween(System.Today())/365.25);
            if(intAge < 18) {
                con.RecordTypeId = mapAppSettings.get('RT_ContactRespondentChild');
            }
            
            // Perform Upsert
            upsert con;
            strMessageDetail = con.Id;
            
            // Data is good, proceed.
            bolProcessedAction = true;
            
        } catch(Exception ex) {
            processResponse(false, 9999, reqBody.actionName, ex.getMessage());
        }		
        
    }
    
    private static void respondentSchedule() {
        // Check Required Data
        if(reqBody.trRespondent == null || reqBody.seSession == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        try{
            
            // Cancel First
            if(!reqBody.overrideCancellation) { // Added 20160202 AAB per Lisa and Morgan to handle linked pair tests (parent cancelling kid unintentionally)
                UtilityMethods.bolPreventMetricRollup = true;
                MasterTestLibrary.cancelRespondentFromSession(reqBody.trRespondent, reqBody.seSession);
                UtilityMethods.bolPreventMetricRollup = false;
            }
            
            // Check for all quotas to be open first - added 20160708 AAB per Lisa
            if(!MasterTestLibrary.checkForOpenQuotaSet(reqBody.trRespondent, reqBody.seSession)) {
                processResponse(false, 2002, reqBody.actionName, 'While we were processing your request, the session you chose filled to capacity.  Please select another session, if one is available, or please try another study if no sessions are displaying at this time.  Check back frequently as we are always filling canceled slots.');
                return;
            }
            
            // Then Schedule
            if(MasterTestLibrary.scheduleRespondentForSession(reqBody.trRespondent, reqBody.seSession)) {
                strMessageDetail = 'Scheduling request was completed successfully';
                bolProcessedAction = true;
            } else {
                processResponse(false, 2000, reqBody.actionName, 'Scheduling request was not completed; there are no available seats in the selected session');
                return;
            }
            
        } catch(Exception ex) {
            processResponse(false, 9999, reqBody.actionName, ex.getMessage());
        }
    }
    
    private static void respondentCancel() {
        // Check Required Data
        if(reqBody.trRespondent == null || reqBody.seSession == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        try{
            if(MasterTestLibrary.cancelRespondentFromSession(reqBody.trRespondent, reqBody.seSession)) {
                strMessageDetail = 'Scheduling cancellation request was completed successfully';
            } else {
                strMessageDetail = 'Scheduling cancellation was not completed; there were no sessions to cancel!';
            }
            
            bolProcessedAction = true;
            
        } catch(Exception ex) {
            processResponse(false, 9999, reqBody.actionName, ex.getMessage());
        }
    }
    
    private static void respondentRefreshDate() {
        
        // Check Required Data
        if(reqBody.conRespondent == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        // Set Initial Data and Variables
        Map<String, String> mapAppSettings = UtilityMethods.APP_SETTINGS();
        Set<Id> setRespondentRTs = new Set<Id>();
        
        setRespondentRTs.add(mapAppSettings.get('RT_ContactRespondentAdult'));
        setRespondentRTs.add(mapAppSettings.get('RT_ContactRespondentChild'));
        
        List<Contact> lstContacts = [SELECT Id FROM Contact WHERE RecordTypeId IN :setRespondentRTs AND LastModifiedDate > :reqBody.conRespondent.LastModifiedDate];
        update lstContacts;
        
        // Data is good, proceed.
        strMessageDetail = 'Refresh will be pushed via SQS';
        bolProcessedAction = true;
        
    }
    
    private static void respondentCheck() {
        
        // Check Required Data
        if(reqBody.conRespondent == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        String email = reqBody.conRespondent.email;
        Map<String, String> mapAppSettings = UtilityMethods.APP_SETTINGS();
        Set<Id> setRespondentRTs = new Set<Id>();
        
        setRespondentRTs.add(mapAppSettings.get('RT_ContactRespondentAdult'));
        setRespondentRTs.add(mapAppSettings.get('RT_ContactRespondentChild'));
        
        List<Contact> lstContacts = new List<Contact>([SELECT Id FROM Contact WHERE RecordTypeId IN :setRespondentRTs AND Email = :email]);
        System.debug('DC: lstContacts: ' + lstContacts);
        
        if(lstContacts == null || lstContacts.size() <= 0) {
            strMessageDetail = 'No contacts found.';
            bolProcessedAction = false;
            
        }
        if(lstContacts.size() > 1) {
            strMessageDetail = 'Multiple contacts found.';
            bolProcessedAction = true;
        }
        
        if(lstContacts.size() == 1) {
            strMessageDetail = 'Contact found.';
            bolProcessedAction = true;
        }
        
        System.debug('DC: strMessageDetail: ' + strMessageDetail);
        System.debug('DC: bolProcessedAction: ' + bolProcessedAction);
        
    }
    
    private static void respondentRefresh() {
        
        // Check Required Data
        if(reqBody.conRespondent == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        // Set Initial Data and Variables
        Contact conRefresh = new Contact(Id=reqBody.conRespondent.Id);
        update conRefresh;
        
        // Data is good, proceed.
        strMessageDetail = 'Refresh will be pushed via SQS';
        bolProcessedAction = true;
        
    }
    
    private static void testRespondentRefresh() {
        
        // Check Required Data
        if(reqBody.trRespondent == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        Test_Respondent__c trRefresh = new Test_Respondent__c(Id=reqBody.trRespondent.Id);
        update trRefresh;
        
        // Data is good, proceed.
        strMessageDetail = 'Refresh will be pushed via SQS';
        bolProcessedAction = true;
        
    }
    
    private static void testExcludedProjects() {
        
        // Check required data
        if(reqBody.mtTest == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        try {
            Master_Test__c mtProjects = [SELECT Id, Excluded_Projects__c FROM Master_Test__c WHERE Id = :reqBody.mtTest.Id LIMIT 1];
            strMessageDetail = mtProjects.Excluded_Projects__c;
            
            // Data is good, proceed.
            bolProcessedAction = true;
            
        } catch(Exception ex) {
            processResponse(false, 9999, reqBody.actionName, ex.getMessage());
        }
        
    }
    
    private static void testAllOpenRecords() {
        
        // No Required Data
        
        // Instanciate Bulk Response object and fill with data
        Map<String, String> SQS_QUEUES = UtilityMethods.SQS_QUEUES();
        WS_WebProcessor.wsResponseBulk bulkResponse = new WS_WebProcessor.wsResponseBulk();
        String strQueryMasterTests = SQS_QUEUES.get('FPIOpenMasterTests');
        String strQuerySessions = SQS_QUEUES.get('FPIOpenSessions');
        String strQueryQuotas = SQS_QUEUES.get('FPIOpenQuotas');
        
        bulkResponse.masterTests = Database.Query(strQueryMasterTests);
        bulkResponse.sessionQuotas = Database.Query(strQueryQuotas);
        bulkResponse.sessions = Database.Query(strQuerySessions);
        
        String strResponseBulk = JSON.serialize(bulkResponse);
        
        strMessageDetail = strResponseBulk;
        bolProcessedAction = true;
        
        
    }
    
    private static void testRefreshDate() {
        // Check Required Data
        if(reqBody.mtTest == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        } 
        
        //try{
        
        // Set Initial Data and Variables
        Map<Id, Master_Test__c> mapMTUpdates = new Map<Id, Master_Test__c>(
            [SELECT Id FROM Master_Test__c 
             WHERE LastModifiedDate > :reqBody.mtTest.LastModifiedDate]
        );
        Map<Id, Test_Respondent__c> mapRespondents = new Map<Id, Test_Respondent__c>(
            [SELECT Id, Respondent__c, Tested_Status__c FROM Test_Respondent__c 
             WHERE Master_Test__c IN :mapMTUpdates.keySet()]
        );
        Map<Id, Session__c> mapSessions = new Map<Id, Session__c>(
            [SELECT Id FROM Session__c 
             WHERE Related_Test__c IN :mapMTUpdates.keySet()]
        );
        Map<Id, Session_Quota__c> mapQuotas = new Map<Id, Session_Quota__c>(
            [SELECT Id FROM Session_Quota__c 
             WHERE Related_Session__c IN :mapSessions.keyset()]
        );
        Map<Id, Test_Respondent_Quota__c> mapTRQs = new Map<Id, Test_Respondent_Quota__c>(
            [SELECT Id FROM Test_Respondent_Quota__c 
             WHERE Session_Quota__c IN :mapQuotas.keySet()]
        );
        
        update mapMTUpdates.values();
        update mapRespondents.values();
        update mapSessions.values();
        update mapQuotas.values();
        update mapTRQs.values();
        
        // Perform Upsert
        strMessageDetail = 'Refresh will be pushed via SAPI';
        
        // Data is good, proceed.
        bolProcessedAction = true;
        
        //} catch(Exception ex) {
        //	processResponse(false, 9999, reqBody.actionName, ex.getMessage());
        //}
    }
    
    private static void testRefresh() {
        // Check Required Data
        if(reqBody.mtTest == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        //try{
        
        // Set Initial Data and Variables
        Master_Test__c mtUpdate = new Master_Test__c(Id=reqBody.mtTest.Id);
        Map<Id, Test_Respondent__c> mapRespondents = new Map<Id, Test_Respondent__c>(
            [SELECT Id, Respondent__c, Tested_Status__c FROM Test_Respondent__c 
             WHERE Master_Test__c = :reqBody.mtTest.Id]
        );
        Map<Id, Session__c> mapSessions = new Map<Id, Session__c>(
            [SELECT Id FROM Session__c 
             WHERE Related_Test__c = :reqBody.mtTest.Id]
        );
        Map<Id, Session_Quota__c> mapQuotas = new Map<Id, Session_Quota__c>(
            [SELECT Id FROM Session_Quota__c 
             WHERE Related_Session__c IN :mapSessions.keyset()]
        );
        Map<Id, Test_Respondent_Quota__c> mapTRQs = new Map<Id, Test_Respondent_Quota__c>(
            [SELECT Id FROM Test_Respondent_Quota__c 
             WHERE Session_Quota__c IN :mapQuotas.keySet()]
        );
        
        update mtUpdate;
        update mapRespondents.values();
        update mapSessions.values();
        update mapQuotas.values();
        update mapTRQs.values();
        
        // Perform Upsert
        strMessageDetail = 'Refresh will be pushed via SAPI';
        
        // Data is good, proceed.
        bolProcessedAction = true;
        
        //} catch(Exception ex) {
        //	processResponse(false, 9999, reqBody.actionName, ex.getMessage());
        //}
    }
    
    private static void sessionRefresh() {
        // Check Required Data
        if(reqBody.seSession == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        //try{
        
        // Set Initial Data and Variables
        Map<Id, Session__c> mapSessions = new Map<Id, Session__c>(
            [SELECT Id FROM Session__c 
             WHERE Id = :reqBody.seSession.Id]
        );
        Map<Id, Session_Quota__c> mapQuotas = new Map<Id, Session_Quota__c>(
            [SELECT Id FROM Session_Quota__c 
             WHERE Related_Session__c IN :mapSessions.keyset()]
        );
        Map<Id, Test_Respondent_Quota__c> mapTRQs = new Map<Id, Test_Respondent_Quota__c>(
            [SELECT Id FROM Test_Respondent_Quota__c 
             WHERE Session_Quota__c IN :mapQuotas.keySet()]
        );
        
        update mapSessions.values();
        update mapQuotas.values();
        update mapTRQs.values();
        
        // Perform Upsert
        strMessageDetail = 'Refresh will be pushed via SAPI';
        
        // Data is good, proceed.
        bolProcessedAction = true;
        
        //} catch(Exception ex) {
        //	processResponse(false, 9999, reqBody.actionName, ex.getMessage());
        //}
    }
    
    private static void pollRespondentCreate() {
        
        // Check Required Data
        if(reqBody.pollRespondent == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        // Set Initial Data and Variables
        Poll_Respondent__c pr = reqBody.pollRespondent;
        
        try{
            // Perform Upsert
            upsert pr;
            strMessageDetail = pr.Id;
            
            // Data is good, proceed.
            bolProcessedAction = true;
            
        } catch(Exception ex) {
            processResponse(false, 9999, reqBody.actionName, ex.getMessage());
        }
        
        
    }
    
    private static void respondentCashOut() {
        
        // Check Required Data
        if(reqBody.conRespondent == null || reqBody.jsonBulkData == null) {
            processResponse(false, 1002, reqBody.actionName, null);
            return;
        }
        
        /**
         * JSON should look like... the value will be what they want to be paid out - there could be multiple - if so - we need to create records for each.
            /services/apexrest/actions    
            {
                "actionName": "respondentCashOut",
                "conRespondent": {
                    "id": "003D500000yj5oUIAQ"
                },
                "jsonBulkData": [
                    {
                    "value": "5.00",
                    "key": "amount"
                    }
                ]
                }
         */

        Id respondentId = reqBody.conRespondent.Id;

        Decimal cashOutAmt;
        for(jsonQuestion jq : reqBody.jsonBulkData) {
            if(jq.key == 'amount') {
                System.debug('DC: jq.value: ' + jq.value);
                cashOutAmt = Decimal.valueOf(jq.value);
            }
        }

        if(cashOutAmt != null && cashOutAmt != 0 && respondentId != null) {
            //Create an Engagement Transaction Record
            EngagementTransaction__c et = new EngagementTransaction__c();
            et.EngagementProfile__r = new EngagementProfile__c(External_ID__c = respondentId);
            et.AmountPaid__c = cashOutAmt;
            et.TransactionDate__c = DateTime.now();
            et.Category__c = 'Cash Out';
            insert et;

            //Create a Case Queue record to tell recruiting to the cut the check
            //RT = customer Care Queue
            Id recordTId = Schema.SObjectType.Task_Queue__c.getRecordTypeInfosByName().get('Customer Care Queue').getRecordTypeId();
            Task_Queue__c caseQ = new Task_Queue__c();
            caseQ.RecordTypeId = recordTId;
            caseQ.Name = '*Respondent Cash Out';
            caseQ.Contact_Name__c = respondentId;
            caseQ.Description__c = 'See respondent record for Engagement Transaction.  Respondent has requested a cash out of ' + cashOutAmt + '.';
            insert caseQ;
        }

        // Data is good, proceed.
        strMessageDetail = 'Engagement Transaction and Case Queue created.';
        bolProcessedAction = true;
        
    }
    
    ////////////////////////////////
    // Helper Methods
    ////////////////////////////////
    
    private static void processResponse(Boolean bolSuccess, Integer intErrorCode, String strActionName, String strDetail) {
        
        System.Debug('PROCESS RESPONSE - Code = ' + intErrorCode + ', Success = ' + bolSuccess + ', Message = ' + strDetail);
        
        resp.responseBody = blob.valueOf(JSON.serialize(new wsResponse(bolSuccess, intErrorCode, strActionName, strDetail)));
        bolProcessedAction = bolSuccess;
    }
    
    ////////////////////////////////
    // Inner Classes / Input-Output
    // Definitions
    ////////////////////////////////
    global class wsResponse {
        
        public Boolean status {get;set;}
        public string errorCode {get;set;}
        public string message {get;set;}
        public string messageDetail {get;set;}
        public string requestedAction {get;set;}
        public List<jsonQuestion> messageExtras {get;set;}
        
        public wsResponse(Boolean passStatus, Integer passErrorCode, String passAction, String passMessageDetail) {
            Map<Integer, String> mapStatusCodes = UtilityMethods.STATUS_RESTSERVICE();
            messageExtras = lstMessageExtras;
            status = passStatus;
            errorCode = string.valueOf(passErrorCode);
            message = mapStatusCodes.get(passErrorCode);
            requestedAction = passAction;
            messageDetail = passMessageDetail;
        }
        
        public wsResponse() { 
            // Empty for Unit Test
        }
        
    }
    
    global class wsResponseBulk {
        public List<Contact> contacts {get;set;}
        public List<Household__c> households {get;set;}
        public List<Household_Contact__c> householdcontacts {get;set;}
        public List<Master_Test__c> masterTests {get;set;}
        public List<Session_Quota__c> sessionQuotas {get;set;}
        public List<Session__c> sessions {get;set;}
        public wsResponseBulk() { }
    }
    
    global class wsRequest {
        
        public string actionName {get;set;}
        public boolean overrideCancellation {get;set;}
        public List<jsonQuestion> jsonBulkData {get;set;}
        public Contact conRespondent {get;set;}
        public Boolean isApp {get; set;}
        public Household__c hseHousehold {get;set;}
        public Household_Contact__c hcMember {get;set;}
        public Test_Respondent__c trRespondent {get;set;}
        public Master_Test__c mtTest {get;set;}
        public Session__c seSession {get;set;}
        public Test_Respondent_Quota__c trQuota {get;set;}
        public Session_Quota__c qtSession {get;set;}
        public Account acctFundraising {get;set;}
        public Contact conFundraisingMain {get;set;}
        public Contact conFundraisingCheck {get;set;}
        public Poll_Respondent__c pollRespondent {get; set;}
        
        public wsRequest() { }
        
    }
    
    global class jsonQuestion {
        public string key {get;set;}
        public string value {get;set;}
        public jsonQuestion() { }
        public jsonQuestion(String passKey, String passValue) {
            key = passKey;
            value = passValue;
        }
    }
}