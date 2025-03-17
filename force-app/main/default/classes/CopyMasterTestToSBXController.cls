//Needs to be without sharing so all of these fields can be queried as the System Admin
//
public without sharing class CopyMasterTestToSBXController {
    /**
    *   CHANGE  HISTORY
    *   =============================================================================
    *   Date        Name                    Description
    *   03/25/2020  Robin Lindemann (Demand Chain)
    *               Initial Creation
    *   06/12/2020  Sophia Murphy (Demand Chain)
    *               Copied logic over from "CopyOppsMasterTesttoSBX"
    *               Tied controller to page and established connection
    *               Removed old code
    *   01/14/2021  Sophia Murphy (Demand Chain)
    *               Updated to use fieldsets to determine the fields to copy
    *   11/29/2023  Sophia Murphy (Demand Chain)
    *               Issue with more than 200 records in a batch; breaking up
    *   =============================================================================
    */
        //@TestVisible private String orgName = 'Feb2020';
        @TestVisible private TokenResponse tr;
        @TestVisible private String REST_URI;

        private Master_Test__c thisMT;
        private Id thisOppId;
        private Id thisAcctId;
        private Id newSBXMTId;
        public String statusMessages {get; set;}
        private Boolean doContinue {get; set;}

        //Map of the Production Salesforce Id to the Sandbox Salesforce Id
        public Map<Id, Id> testLocationMap = new Map<Id, Id>();
        public Map<Id, Id> masterQuotaMap = new Map<Id, Id>();
        public Map<Id, Id> sessionMap = new Map<Id, Id>();
        public Map<Id, Id> sessionQuotaMap = new Map<Id, Id>();
    
        //////////////////////////////////
        // CONSTRUCTOR
        //////////////////////////////////
        public CopyMasterTestToSBXController( ){
            //just for running things in the debug console.
            //remove this constructor before deployment
        }
        public CopyMasterTestToSBXController( ApexPages.StandardController stdController ){
            thisMT = (Master_Test__c) stdController.getRecord();
        }
        
        //////////////////////////////////
        // ACTION METHODS
        //////////////////////////////////
        //06.12.2020 - works.  
        public HttpResponse logInToSBX() {
            
            // Get Endpoint and Construct REST URL
            S2S_Setting__mdt objSettings = [SELECT
                                                Authorization_URI__c,
                                                Token_URI__c,
                                                Callback_URI__c,
                                                Client_Id__c,
                                                Client_Secret__c,
                                                Username__c,
                                                Password__c,
                                                REST_URI__c
                                            FROM
                                                S2S_Setting__mdt
                                            WHERE
                                                QualifiedAPIName = 'SandboxConnection'
                                            LIMIT 1
            ];
    
            // Get Login Token and Endpoint
            String body = 'grant_type=password&client_id='
                            + objSettings.Client_Id__c
                            + '&client_secret='
                            + objSettings.Client_Secret__c
                            + '&redirect_uri='
                            + objSettings.Callback_URI__c
                            + '&username='
                            + objSettings.Username__c
                            + '&password='
                            //+ UtilityMethods.decodeString(objSettings.Password__c)
                            + objSettings.Password__c
                            + '&format=json';
    
            Http hToken = new Http();
            HttpRequest req = new HttpRequest();
            req.setHeader('Content-Type','application/x-www-form-urlencoded');
            req.setHeader('Accept', 'application/x-www-form-urlencoded');
            req.setEndpoint(objSettings.Token_URI__c);
            req.setMethod('POST');
            req.setTimeout(100000);
            req.setBody(body);
    
            HttpResponse response = sendRequest(req, '{"access_token":"hello","instance_url":"world"}');
            tr = (TokenResponse)JSON.deserialize(response.getBody(),TokenResponse.class);
            REST_URI = objSettings.REST_URI__c;
            system.debug(tr);

            return response;
        }
        
        public PageReference postMasterTestToSBX() {
            //0. Declare all the lists we're gonna need.
            List<Quota__c> quotasForUpdate = new List<Quota__c>();
            List<Session__c> sessionsForUpdate = new List<Session__c>();
            List<Account> testLocForUpdate = new List<Account>();
            List<Session_Quota__c> sessionQuotasForUpdate = new List<Session_Quota__c>();

            try {
                thisOppId = thisMT.Opportunity__c;
                if(thisOppId == null) {
                    //if this is a platform user; the standard controller won't return the opp or account ids
                    //we'll need to query for them - since this extension runs under system mode
                    thisOppId = [SELECT Opportunity__c FROM Master_Test__c WHERE Id = :thisMT.Id].Opportunity__c;
                }
            } catch(Exception e) {}

            try {
                thisAcctId = thisMT.Opportunity__r.AccountId;
                if(thisAcctId == null && thisOppId != null) {
                    //if this is a platform user; the standard controller won't return the opp or account ids
                    //we'll need to query for them - since this extension runs under system mode
                    thisAcctId = [SELECT Opportunity__r.AccountId FROM Master_Test__c WHERE Id = :thisMT.Id].Opportunity__r.AccountId;
                }
            } catch(Exception e) {}

            //1. Login!
            doContinue = true;
            statusMessages = '';
            HttpResponse loginResponse = logInToSBX();
            system.debug(loginResponse);
            addResponseToMsg('Login Response', loginResponse);

            //2. Send/Update the Account
            if(doContinue && thisAcctId != null) {
                String acctJsonBody = buildAcctJson(thisAcctId);
                HttpResponse acctResponse = sendSingleRecord('Account', thisAcctId, acctJsonBody);
                addResponseToMsg('Account Creation/Update', acctResponse);
            }

            //3. Send/Update the Opportunity
            if(doContinue && thisOppId != null) {
                String oppJsonBody = buildOppJson(thisOppId, thisAcctId);
                HttpResponse oppResponse = sendSingleRecord('Opportunity', thisOppId, oppJsonBody);
                addResponseToMsg('Opportunity Creation/Update', oppResponse);
            }

            //4. Send/Update the Master Test
            if(doContinue) {
                String mtJsonBody = buildMTJson(thisMT.Id, thisOppId);
                HttpResponse mtResponse = sendSingleRecord('Master_Test__c', thisMT.Id, mtJsonBody);
                addResponseToMsg('Master Test Creation/Update', mtResponse);
            }
            
            //4.5 - Get the Master Test ID from the Sandbox and update the Master Test record
            if(doContinue) {
                newSBXMTId = getMasterTestIdFromSandbox(thisMT.Id);
                addStringToMsg('Master Test in Sandbox has Id of ' + newSBXMTId);
            }
        
            //5. Send/Update the Master Quotas
                //We need to query for all Master Quotas in THIS org.
                //Then query for all Master Quotas in the SANDBOX org.
                //The existing SBX MQs need to be UPDATED; the others need to be created from scratch
            if(doContinue) {
                masterQuotaMap = new Map<Id, Id>();

                List<Quota__c> mqsInThisOrg = new List<Quota__c>([SELECT Id, Sandbox_Salesforce_Id__c FROM Quota__c 
                        WHERE Related_Test__c = :thisMT.Id]);
                
                Set<Id> createMQs = new Set<Id>();
                Set<Id> updateMQs = new Set<Id>();

                for(Quota__c q : mqsInThisOrg) {
                    //System.debug('DC: q.Sandbox_Salesforce_Id__c: ' + q.Sandbox_Salesforce_Id__c);
                    if(q.Sandbox_Salesforce_Id__c == null) {
                        createMQs.add(q.Id);
                    } else {
                        updateMQs.add(q.Id);
                        masterQuotaMap.put(q.Id, q.Sandbox_Salesforce_Id__c);
                    }
                }

                system.debug('DC: ' + createMQs);
                system.debug('DC: ' + updateMQs);

                //we need to POST new records
                if(createMQs.size() > 0) {
                    HttpResponse mqResponse_Create = sendListRecords_POST('Quota__c', buildMQJson_Create(createMQs));
                    addResponseToMsg('Master Quotas Creation', mqResponse_Create);
                    //after creating the records... do the buildListForUpdate to update the records.
                    quotasForUpdate = (List<Quota__c>)buildListForUpdate(mqResponse_Create, 'Quota__c');
                    for(Quota__c q : quotasForUpdate) {
                        masterQuotaMap.put(q.Id, q.Sandbox_Salesforce_Id__c);
                    }
                }
                //... and UPDATE the existing records, one at a time.  
                if(updateMQs.size() > 0) {
                    String mqJson = buildMQJson_Update(updateMQs);
                    HttpResponse mqResponse_Update = sendListRecords_PATCH('Quota__c', mqJson);
                    addResponseToMsg('Master Quotas Update', mqResponse_Update);
                }
            }

            //5.5 Send/Update the Testing Location Accounts
            if(doContinue) {
                testLocationMap = new Map<Id, Id>();

                List<Session__c> sessionsInThisOrg = new List<Session__c>([SELECT Id, Testing_Location__c, Testing_Location__r.Sandbox_Salesforce_Id__c FROM Session__c 
                WHERE Related_Test__c = :thisMT.Id]);

                Set<Id> testingLocations = new Set<Id>();
            
                for(Session__c sess : sessionsInThisOrg) {
                    if(sess.Testing_Location__c != null && (sess.Testing_Location__r.Sandbox_Salesforce_Id__c == '' || sess.Testing_Location__r.Sandbox_Salesforce_Id__c == null) ) {
                        //If the testingLocation has a Sandbox Salesforce Id; it's already there - we're not going to update them.
                        // we just need the IDs in there to ensure we can relate them to the right spots.
                        testingLocations.add(sess.Testing_Location__c);
                    } 
                    //If we already know it's in sandbox; just get the ids loaded into the testLocationMap
                    // so we can use them to match up the sessions correctly
                    if(sess.Testing_Location__r.Sandbox_Salesforce_Id__c != null) {
                        testLocationMap.put(sess.Testing_Location__c, sess.Testing_Location__r.Sandbox_Salesforce_Id__c);
                    }
                }

                if(testingLocations.size() > 0) {
                    HttpResponse testLocResponse_Create = sendListRecords_POST('Account', buildTestingLocationsJson_Create(testingLocations));
                    addResponseToMsg('Testing Locations Creation', testLocResponse_Create);
                    //after creating the records... do the buildListForUpdate to update the records.
                    testLocForUpdate = (List<Account>)buildListForUpdate(testLocResponse_Create, 'Account');
                    //We do need a mappping of the IDs though - to use in the Session upload
                    for(Account a : testLocForUpdate) {
                        testLocationMap.put(a.Id, a.Sandbox_Salesforce_Id__c);
                    }
                } 
            }

            //6. Send/Update the Sessions
                //Related_Test__c
            if(doContinue) {
                sessionMap = new Map<Id, Id>();

                List<Session__c> sessionsInThisOrg = new List<Session__c>([SELECT Id, Sandbox_Salesforce_Id__c, Testing_Location__c FROM Session__c 
                        WHERE Related_Test__c = :thisMT.Id]);
                
                Set<Id> createSessions = new Set<Id>();
                Set<Id> updateSessions = new Set<Id>();
                Set<Id> sessionList = new Set<Id>();

                for(Session__c sess : sessionsInThisOrg) {
                    if(sess.Sandbox_Salesforce_Id__c == null) {
                        createSessions.add(sess.Id);
                    } else {
                        updateSessions.add(sess.Id);
                        sessionMap.put(sess.Id, sess.Sandbox_Salesforce_Id__c);
                    }
                }

                system.debug('DC: ' + createSessions);
                system.debug('DC: ' + updateSessions);

                //we need to POST new records
                if(createSessions.size() > 0) {
                    HttpResponse sessResponse_Create = sendListRecords_POST('Session__c', buildSessionJson_Create(createSessions));
                    addResponseToMsg('Session Creation', sessResponse_Create);
                    //after creating the records... do the buildListForUpdate to update the records.
                    sessionsForUpdate = (List<Session__c>)buildListForUpdate(sessResponse_Create, 'Session__c');
                    for(Session__c s : sessionsForUpdate) {
                        sessionMap.put(s.Id, s.Sandbox_Salesforce_Id__c);
                    }
                }
                
                //... and UPSERT the existing records, one at a time
                if(updateSessions.size() > 0) {
                    String json = buildSessionJson_Update(updateSessions);
                    HttpResponse sessResponse_Update = sendListRecords_PATCH('Session__c', json);
                    addResponseToMsg('Session Update', sessResponse_Update);
                }
            }  

            //7. Send/Update the Session Quotas
                //Related_Session__c
                //Master_Quota__c
            if(doContinue) {
                sessionQuotaMap = new Map<Id, Id>();

                List<Session_Quota__c> sessionsInThisOrg = new List<Session_Quota__c>([SELECT Id, Sandbox_Salesforce_Id__c FROM Session_Quota__c 
                        WHERE Related_Session__c IN :sessionMap.keySet()
			            AND Master_Quota__c IN :masterQuotaMap.keySet()]);
                
                Set<Id> createSessions = new Set<Id>();
                Set<Id> updateSessions = new Set<Id>();
                Set<Id> sessionList = new Set<Id>();

                Map<Integer, Set<Id>> map_createSessions = new Map<Integer, Set<Id>>();
                Map<Integer, Set<Id>> map_updateSessions = new Map<Integer, Set<Id>>();

                Integer createMapCounter = 0;
                Integer updateMapCounter = 0;

                for(Session_Quota__c sess : sessionsInThisOrg) {
                    if(sess.Sandbox_Salesforce_Id__c == null) {
                        createSessions.add(sess.Id);
                    } else {
                        updateSessions.add(sess.Id);
                        sessionQuotaMap.put(sess.Id, sess.Sandbox_Salesforce_Id__c);
                    }

                    if(createSessions.size() >= 200) {
                        map_createSessions.put(createMapCounter, createSessions);
                        createMapCounter++;
                        createSessions.clear();
                    }
                    if(updateSessions.size() >= 200) {
                        map_updateSessions.put(updateMapCounter, updateSessions);
                        updateMapCounter++;
                        updateSessions.clear();
                    }
                }

                //outside of the loop, make sure the remaining get added to the maps
                if(createSessions.size() > 0) {
                    map_createSessions.put(createMapCounter, createSessions);
                }
                if(updateSessions.size() > 0) {
                    map_updateSessions.put(updateMapCounter, updateSessions);
                }

                system.debug('DC: ' + createSessions);
                system.debug('DC: ' + updateSessions);

                system.debug('DC: ' + map_createSessions);
                system.debug('DC: ' + map_updateSessions);

                //we need to POST new records
                if(map_createSessions.size() > 0) {

                    //To account for more than 200 session quotas - this is in a loop.
                    // Yes, I know this is running a query in a loop.
                    for(Integer mapX : map_createSessions.keySet()) {

                        Set<Id> sessions = map_createSessions.get(mapX);

                        //HttpResponse sessResponse_Create = sendListRecords_POST('Session_Quota__c', buildSessionQuotaJson_Create(createSessions));
                        HttpResponse sessResponse_Create = sendListRecords_POST('Session_Quota__c', buildSessionQuotaJson_Create(sessions));
                        addResponseToMsg('Session Quota Creation', sessResponse_Create);
                        //after creating the records... do the buildListForUpdate to update the records.
                        sessionQuotasForUpdate = (List<Session_Quota__c>)buildListForUpdate(sessResponse_Create, 'Session_Quota__c');
                        for(Session_Quota__c s : sessionQuotasForUpdate) {
                            sessionQuotaMap.put(s.Id, s.Sandbox_Salesforce_Id__c);
                        }
                    }
                }
                if(map_updateSessions.size() > 0) {
                    for(Integer mapX : map_updateSessions.keySet()) {
                        Set<Id> sessions = map_updateSessions.get(mapX);

                        String json = buildSessionQuotaJson_Update(sessions);
                        HttpResponse sessResponse_Update = sendListRecords_PATCH('Session_Quota__c', json);
                        addResponseToMsg('Session Quota Update', sessResponse_Update);
                    }
                }
            }  

            //8. Send/Update the Linked Sessions
                //Related_Session__c
                //Master_Quota__c
            if(doContinue) {
                //Linked sessions are just updating existing sessions; with the id of the one its linked to
                //so we just need to query for the sessions that have linked sessions related to them.
                sessionMap = new Map<Id, Id>();

                List<Session__c> sessionsInThisOrg = new List<Session__c>([SELECT Id, Sandbox_Salesforce_Id__c FROM Session__c 
                        WHERE Related_Test__c = :thisMT.Id
                        AND Linked_Session__c != null]);
                
                Set<Id> updateSessions = new Set<Id>();
                
                for(Session__c sess : sessionsInThisOrg) {
                        updateSessions.add(sess.Id);
                }

                if(updateSessions.size() > 0) {
                    system.debug('DC: inside the update');
                    for(Id sessId : updateSessions) {

                        HttpResponse sessResponse_Update = sendSingleRecord('Session__c', sessId, buildLinkedSessionJson_Update(sessId));
                        addResponseToMsg('Linked Session Update (' + sessId + ')', sessResponse_Update);
                    }
                }
            }

            //9. FINAL - update records
                //Save the Sandbox Salesforce Ids to the records.
            if(doContinue) {
                Master_Test__c myMT = new Master_Test__c(Id = thisMT.Id);
                myMT.Sandbox_Salesforce_Id__c = newSBXMTId;
                update myMT;    

                system.debug('DC: quotasForUpdate.size(): ' + quotasForUpdate.size());
                if(quotasForUpdate.size() > 0 && !Test.isRunningTest()) {
                    update quotasForUpdate;
                }
                system.debug('DC: testLocForUpdate.size(): ' + testLocForUpdate.size());
                if(testLocForUpdate.size() > 0 && !Test.isRunningTest()) {
                    update testLocForUpdate;
                }
                system.debug('DC: sessionsForUpdate.size(): ' + sessionsForUpdate.size());
                if(sessionsForUpdate.size() > 0 && !Test.isRunningTest()) {
                    update sessionsForUpdate;
                }
                system.debug('DC: sessionQuotasForUpdate.size(): ' + sessionQuotasForUpdate.size());
                if(sessionQuotasForUpdate.size() > 0 && !Test.isRunningTest()) {
                    update sessionQuotasForUpdate;
                }
            }

            addStringToMsg('Job Complete');
    
            return null;
        }

        //This can be used for Master Quotas, Session and Session Quotas.
        // any list of records that have "Sandbox_Salesforce_Id__c" as a field.
        // will take the results after pushing to sandbox; and update the records with the Sandbox Id.
        public List<sObject> buildListForUpdate(HttpResponse httpR, String objName) {
            //Given the http response - deserialize int json
            hClsQuery qryList = (hClsQuery)JSON.deserialize(httpR.getBody(), hClsQuery.class);
            List<hClsResults> resultList = qryList.results;
            
            List<sObject> returnList = new List<sObject>();
            for(hClsResults hcr : resultList) {

                sObject so = Schema.getGlobalDescribe().get(objName).newSObject() ;
                so.put('Id', hcr.referenceId);
                so.put('Sandbox_Salesforce_Id__c', hcr.Id);

                //sObject so = new sObject(Id = hcr.referenceId);
                //so.Sandbox_Salesforce_Id__c = hcr.Id;
                returnList.add(so);
            }

            return returnList;
        }

        public HttpResponse sendListRecords_POST(String objName, String jsonBody) {
            //Using this method assumes that your object has an external ID field called Production_Salesforce_Id__c
            Http httpProtocol = new Http();
            HttpRequest req =  new HttpRequest();
            
            req.setHeader('Content-Type','application/json');
            req.setHeader('Accept', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + tr.access_token);
    
            //String endpoint = 'https://fpicfs--feb2020.my.salesforce.com/services/data/v34.0/composite/tree/' + objName;
            String endpoint = REST_URI + '/services/data/v34.0/composite/tree/' + objName;
            
            req.setEndpoint(endpoint);
            req.setMethod('POST');  //must be patch for an upsert
            //can't do upsert with external ids in a TREE call.  have to use POST
            req.setTimeout(100000);
            req.setBody(jsonBody);
    
            //HttpResponse response = httpProtocol.send(req);
            HttpResponse response = sendRequest(req, '{"hasErrors":false,"results":[{"referenceId":"' + newSBXMTId + '","id":"' + newSBXMTId + '"}]}');
            system.debug(response.getBody());
            system.debug((hClsQuery)JSON.deserialize(response.getBody(), hClsQuery.class));
            return response;
        }

        public HttpResponse sendListRecords_PATCH(String objName, String jsonBody) {
            //Using this method assumes that your object has an external ID field called Production_Salesforce_Id__c
            Http httpProtocol = new Http();
            HttpRequest req =  new HttpRequest();
            
            req.setHeader('Content-Type','application/json');
            req.setHeader('Accept', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + tr.access_token);
    
            //curl https://yourInstance.salesforce.com/services/data/v20.0/sobjects/Account/001D000000INjVe -H "Authorization: Bearer token" -H "Content-Type: application/json" -d @patchaccount.json -X PATCH
            //must be v48 or higher.  v39 does not work!
            //String endpoint = 'https://fpicfs--feb2020.my.salesforce.com/services/data/v48.0/composite/sobjects';  //do not need the object name on here.
            String endpoint = REST_URI + '/services/data/v48.0/composite/sobjects';  //do not need the object name on here.
            
            req.setEndpoint(endpoint);
            req.setMethod('PATCH');  //must be patch for an update
            req.setTimeout(100000);
            req.setBody(jsonBody);
    
            //HttpResponse response = httpProtocol.send(req);
            HttpResponse response = sendRequest(req, '[{"id":"ID1","success":true,"errors":[]},{"id":"ID2","success":true,"errors":[]}]');
            system.debug(response.getBody());
            //system.debug((hClsQuery)JSON.deserialize(response.getBody(), hClsQuery.class));
            return response;
        }

        public HttpResponse sendSingleRecord(String objName, Id thisObjId, String jsonBody) {
            //Using this method assumes that your object has an external ID field called Production_Salesforce_Id__c
            //Http httpProtocol = new Http();
            HttpRequest req =  new HttpRequest();
            
            req.setHeader('Content-Type','application/json');
            req.setHeader('Accept', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + tr.access_token);
    
            //String endpoint = 'https://fpicfs--feb2020.my.salesforce.com/services/data/v34.0/sobjects/' + objName + '/Production_Salesforce_Id__c/' + thisObjId;
            String endpoint = REST_URI + '/services/data/v34.0/sobjects/' + objName + '/Production_Salesforce_Id__c/' + thisObjId;
            
            req.setEndpoint(endpoint);
            req.setMethod('PATCH');  //must be patch for an upsert
            req.setTimeout(100000);
            req.setBody(jsonBody);
    
            //HttpResponse response = httpProtocol.send(req);
            HttpResponse response = sendRequest(req, '');
            system.debug(response.getBody());
            return response;
        }

        public String buildSessionQuotaJson_Update(Set<Id> recordIds) {
            List<String> selectFields = UtilityMethods.fieldSetFields('Session_Quota__c', 'CopyMasterTest');

            //Build out the query with every field possible!
            String qry = 'SELECT Id, Sandbox_Salesforce_Id__c, ' + String.join(selectFields,',') + ' FROM Session_Quota__c WHERE Id IN :recordIds';
            //addStringToMsg(qry);

            System.debug('DC: qry: ' + qry);
            List<Session_Quota__c> initialList = Database.query(qry);
            List<Session_Quota__c> sendList = new List<Session_Quota__c>();

            for(Session_Quota__c initialRecord : initialList) {
                Session_Quota__c sendRecord = initialRecord.clone(false, true, false, false);
                sendRecord.Production_Salesforce_Id__c = initialRecord.Id;
                sendRecord.Id = initialRecord.Sandbox_Salesforce_Id__c;
                sendRecord.Sandbox_Salesforce_Id__c = '';

                sendList.add(sendRecord);
            }

            //Need to add the "records" at the front for multiple records going across...
            String jsonStr = json.serialize(sendList);
            jsonStr = '{"records":' + jsonStr + '}';
            return jsonStr;  
        }
        
        public String buildSessionQuotaJson_Create(Set<Id> recordIds) {
            List<String> selectFields = UtilityMethods.fieldSetFields('Session_Quota__c', 'CopyMasterTest');
    
            //Build out the query with every field possible!
            String qry = 'SELECT Id, ' + String.join(selectFields,',') + ' FROM Session_Quota__c WHERE Id = :recordIds ';
            
            //addStringToMsg(qry);
            System.debug('DC: qry: ' + qry);
            List<Session_Quota__c> initialList = Database.query(qry);
            List<Session_Quota__c> sendList = new List<Session_Quota__c>();
            String recordJson = '';
            for(Session_Quota__c initialRecord : initialList) {
                Session_Quota__c sendRecord = initialRecord.clone(false, false, false, false);
                sendRecord.Production_Salesforce_Id__c = initialRecord.Id;
                if(initialRecord.Related_Session__c != null) {
                    sendRecord.Related_Session__c = sessionMap.get(initialRecord.Related_Session__c);
                }
                if(initialRecord.Master_Quota__c != null) {
                    sendRecord.Master_Quota__c = masterQuotaMap.get(initialRecord.Master_Quota__c);
                }

                //We need the "referenceId" in the list - so I'm just plugging it in where needed...
                // not the most elegant solution, I know.
                String singleJson = json.serialize(sendRecord);
                String addInRefId = ', "referenceId":"' + initialRecord.Id + '"';
                singleJson = singleJson.replace('"type":"Session_Quota__c"', '"type":"Session_Quota__c"' + addInRefId);
                recordJson += singleJson + ',';

                sendList.add(sendRecord);
            }
            
            //Need to add the "records" at the front for multiple records going across...
            //removing trailing comma
            system.debug('DC: ' + recordJson);
            recordJson = recordJson.substring(0,recordJson.length()-1);
            String jsonStr = '{"records":[' + recordJson + ']}';
            system.debug('DC: jsonStr: ' + jsonStr);
            return jsonStr;
        }  

        public String buildLinkedSessionJson_Update(Id thisOrgSessionId) {
            
            String qry = 'SELECT Id, Sandbox_Salesforce_Id__c, Linked_Session__c FROM Session__c WHERE Id = \'' + thisOrgSessionId + '\' ';
            //addStringToMsg(qry);
            System.debug('DC: qry: ' + qry);
            List<Session__c> sessionList = Database.query(qry);
            Session__c sess = sessionList[0];
    
            Session__c sendSession = sess.clone(false, false, false, false);
            if(sess.Linked_Session__c != null) {
                sendSession.Linked_Session__c = sessionMap.get(sess.Linked_Session__c);
            }

            //serialize our single account record and send it back!
            String jsonStr = json.serialize(sendSession);
            system.debug(jsonStr);
    
            return jsonStr;
        }

        public String buildSessionJson_Update(Set<Id> recordIds) {

            List<String> selectFields = UtilityMethods.fieldSetFields('Session__c', 'CopyMasterTest');

            //Build out the query with every field possible!
            String qry = 'SELECT Id, Sandbox_Salesforce_Id__c, ' + String.join(selectFields,',') + ' FROM Session__c WHERE Id IN :recordIds';

            System.debug('DC: qry: ' + qry);
            List<Session__c> initialList = Database.query(qry);
            List<Session__c> sendList = new List<Session__c>();

            for(Session__c initialRecord : initialList) {
                Session__c sendRecord = initialRecord.clone(false, true, false, false);
                //this is an update, we don't need to set the Test again
                //sendRecord.Related_Test__c = newSBXMTId;
                sendRecord.Production_Salesforce_Id__c = initialRecord.Id;
                sendRecord.Id = initialRecord.Sandbox_Salesforce_Id__c;
                sendRecord.Sandbox_Salesforce_Id__c = '';

                sendList.add(sendRecord);
            }

            //Need to add the "records" at the front for multiple records going across...
            String jsonStr = json.serialize(sendList);
            jsonStr = '{"records":' + jsonStr + '}';
            return jsonStr;
        }
/**
        public String buildSessionJson_Update(Id thisOrgSessionId) {
            List<String> skipFields = new List<String>();
            skipFields.add('related_test__c');
            skipFields.add('sandbox_salesforce_id__c');
            skipFields.add('linked_session_temp__c');
            skipFields.add('linked_session__c');
            
            List<String> selectFields = editableFields('Session__c', skipFields);
    
            //Build out the query with every field possible!
            String qry = 'SELECT Id, ' + String.join(selectFields,',') + ' FROM Session__c WHERE Id = \'' + thisOrgSessionId + '\' ';
            //addStringToMsg(qry);

            List<Session__c> sessionList = Database.query(qry);
            Session__c sess = sessionList[0];
    
            Session__c sendSession = sess.clone(false, false, false, false);
            if(sess.Testing_Location__c != null) {
                //sendSession.Testing_Location__r = new Account(Production_Salesforce_Id__c = sess.Testing_Location__c);
                //sendSession.Testing_Location__c = null;
                sendSession.Testing_Location__c = testLocationMap.get(sess.Testing_Location__c);
            }

            //serialize our single account record and send it back!
            String jsonStr = json.serialize(sendSession);
            system.debug(jsonStr);
    
            return jsonStr;
        }
*/       
        public String buildSessionJson_Create(Set<Id> recordIds) {
            List<String> selectFields = UtilityMethods.fieldSetFields('Session__c', 'CopyMasterTest');
    
            //Build out the query with every field possible!
            String qry = 'SELECT Id, ' + String.join(selectFields,',') + ' FROM Session__c WHERE Id = :recordIds ';
            
            //addStringToMsg(qry);

            System.debug('DC: qry: ' + qry);
            List<Session__c> initialList = Database.query(qry);
            List<Session__c> sendList = new List<Session__c>();
            String recordJson = '';
            for(Session__c initialRecord : initialList) {
                Session__c sendRecord = initialRecord.clone(false, false, false, false);
                sendRecord.Related_Test__c = newSBXMTId;
                sendRecord.Production_Salesforce_Id__c = initialRecord.Id;
                if(initialRecord.Testing_Location__c != null) {
                    //sendRecord.Testing_Location__r = new Account(Production_Salesforce_Id__c = initialRecord.Testing_Location__c);
                    //sendRecord.Testing_Location__c = null;
                    sendRecord.Testing_Location__c = testLocationMap.get(initialRecord.Testing_Location__c);
                }

                //We need the "referenceId" in the list - so I'm just plugging it in where needed...
                // not the most elegant solution, I know.
                String singleJson = json.serialize(sendRecord);
                String addInRefId = ', "referenceId":"' + initialRecord.Id + '"';
                singleJson = singleJson.replace('"type":"Session__c"', '"type":"Session__c"' + addInRefId);
                recordJson += singleJson + ',';

                sendList.add(sendRecord);
            }
            
            //Need to add the "records" at the front for multiple records going across...
            //removing trailing comma
            system.debug('DC: ' + recordJson);
            recordJson = recordJson.substring(0,recordJson.length()-1);
            String jsonStr = '{"records":[' + recordJson + ']}';
            system.debug('DC: jsonStr: ' + jsonStr);
            return jsonStr;
        } 

        public String buildMQJson_Create(Set<Id> recordIds) {
            
            List<String> selectFields = UtilityMethods.fieldSetFields('Quota__c', 'CopyMasterTest');
    
            //Build out the query with every field possible!
            String qry = 'SELECT Id, ' + String.join(selectFields,',') + ' FROM Quota__c WHERE Id = :recordIds ';
            
            //addStringToMsg(qry);

            System.debug('DC: qry: ' + qry);
            List<Quota__c> initialList = Database.query(qry);
            List<Quota__c> sendList = new List<Quota__c>();
            String recordJson = '';
            for(Quota__c initialRecord : initialList) {
                Quota__c sendRecord = initialRecord.clone(false, false, false, false);
                sendRecord.Related_Test__c = newSBXMTId;
                sendRecord.Production_Salesforce_Id__c = initialRecord.Id;

                //We need the "referenceId" in the list - so I'm just plugging it in where needed...
                // not the most elegant solution, I know.
                String singleJson = json.serialize(sendRecord);
                String addInRefId = ', "referenceId":"' + initialRecord.Id + '"';
                singleJson = singleJson.replace('"type":"Quota__c"', '"type":"Quota__c"' + addInRefId);
                recordJson += singleJson + ',';

                sendList.add(sendRecord);
            }
            
            //Need to add the "records" at the front for multiple records going across...
            //removing trailing comma
            system.debug('DC: ' + recordJson);
            recordJson = recordJson.substring(0,recordJson.length()-1);
            String jsonStr = '{"records":[' + recordJson + ']}';
            system.debug('DC: jsonStr: ' + jsonStr);
            return jsonStr;
        }
        
        public String buildMQJson_Update(Set<Id> recordIds) {
            
            List<String> selectFields = UtilityMethods.fieldSetFields('Quota__c', 'CopyMasterTest');
    
            //Build out the query with every field possible!
            String qry = 'SELECT Id, Sandbox_Salesforce_Id__c, ' + String.join(selectFields,',') + ' FROM Quota__c WHERE Id = :recordIds ';
            
            System.debug('DC: qry: ' + qry);
            List<Quota__c> initialList = Database.query(qry);
            List<Quota__c> sendList = new List<Quota__c>();
            
            for(Quota__c initialRecord : initialList) {
                Quota__c sendRecord = initialRecord.clone(false, true, false, false);
                //this is an update, we don't need to set the Test again
                //sendRecord.Related_Test__c = newSBXMTId;
                sendRecord.Production_Salesforce_Id__c = initialRecord.Id;
                sendRecord.Id = initialRecord.Sandbox_Salesforce_Id__c;
                sendRecord.Sandbox_Salesforce_Id__c = '';

                sendList.add(sendRecord);
            }
            
            //Need to add the "records" at the front for multiple records going across...
            String jsonStr = json.serialize(sendList);
            jsonStr = '{"records":' + jsonStr + '}';
            return jsonStr;
        }


        public String buildMTJson(Id thisMTId, Id thisOrgOppId) {
            List<String> selectFields = UtilityMethods.fieldSetFields('Master_Test__c', 'CopyMasterTest');
    
            //Build out the query with every field possible!
            String qry = 'SELECT Id, ' + String.join(selectFields,',') + ' FROM Master_Test__c WHERE Id = \'' + thisMTId + '\' ';
            //addStringToMsg(qry);

            System.debug('DC: qry: ' + qry);
            List<Master_Test__c> myList = Database.query(qry);
            Master_Test__c initialRecord = myList[0];
    
            Master_Test__c sendRecord = initialRecord.clone(false, false, false, false);
            if(thisOrgOppId != null) {
                sendRecord.Opportunity__r = new Opportunity(Production_Salesforce_Id__c = thisOrgOppId);
            }
            
            String jsonStr = json.serialize(sendRecord);
            system.debug(jsonStr);
    
            return jsonStr;
        }
       
        public String buildOppJson(Id thisOrgOppId, Id thisOrgAcctId) {
            List<String> selectFields = UtilityMethods.fieldSetFields('Opportunity', 'CopyMasterTest');
    
            //Build out the query with every field possible!
            String qry = 'SELECT Id, ' + String.join(selectFields,',') + ' FROM Opportunity WHERE Id = \'' + thisOrgOppId + '\' ';
            //addStringToMsg(qry);

            System.debug('DC: qry: ' + qry);
            List<Opportunity> oppList = Database.query(qry);
            Opportunity opp = oppList[0];
    
            Opportunity sendOpp = opp.clone(false, false, false, false);
            if(thisOrgAcctId != null) {
                sendOpp.Account = new Account(Production_Salesforce_Id__c = thisOrgAcctId);
            }
            
            String jsonStr = json.serialize(sendOpp);
            system.debug(jsonStr);
    
            return jsonStr;
        }

        public String buildTestingLocationsJson_Create(Set<Id> recordIds) {
            List<String> selectFields = UtilityMethods.fieldSetFields('Account', 'CopyMasterTest');
    
            //Build out the query with every field possible!
            String qry = 'SELECT Id, ' + String.join(selectFields,',') + ' FROM Account WHERE Id = :recordIds ';
            
            //addStringToMsg(qry);

            System.debug('DC: qry: ' + qry);
            List<Account> initialList = Database.query(qry);
            List<Account> sendList = new List<Account>();
            String recordJson = '';
            for(Account initialRecord : initialList) {
                Account sendRecord = initialRecord.clone(false, false, false, false);
                //sendRecord.Related_Test__c = newSBXMTId;
                sendRecord.Production_Salesforce_Id__c = initialRecord.Id;

                //We need the "referenceId" in the list - so I'm just plugging it in where needed...
                // not the most elegant solution, I know.
                String singleJson = json.serialize(sendRecord);
                String addInRefId = ', "referenceId":"' + initialRecord.Id + '"';
                singleJson = singleJson.replace('"type":"Account"', '"type":"Account"' + addInRefId);
                recordJson += singleJson + ',';

                sendList.add(sendRecord);
            }
            
            //Need to add the "records" at the front for multiple records going across...
            //removing trailing comma
            system.debug('DC: ' + recordJson);
            recordJson = recordJson.substring(0,recordJson.length()-1);
            String jsonStr = '{"records":[' + recordJson + ']}';
            system.debug('DC: jsonStr: ' + jsonStr);
            return jsonStr;
        }

        public String buildAcctJson(Id thisOrgAcctId) {
            //given the Account Id in this org...
            // query for everything we know about it.
            // send back the json
            List<String> selectFields = UtilityMethods.fieldSetFields('Account', 'CopyMasterTest');
    
            //Build out the query with every field possible!
            String qry = 'SELECT Id, ' + String.join(selectFields,',') + ' FROM Account WHERE Id = \'' + thisOrgAcctId + '\' ';
            //addStringToMsg(qry);

            //Test query with less data if needed...
            //String qry = 'SELECT Name FROM Account WHERE Id = \'' + thisOrgAcctId + '\' ';
    
            //Our query will return a list, but we just want the first one - at least for accounts
            System.debug('DC: qry: ' + qry);
            List<Account> acctList = Database.query(qry);
            Account a = acctList[0];
    
            //We can't send the account record as is - because it contains the ID - we need to clone it.
            Account sendAcct = a.clone(false, false, false, false);
            //This does not need to be set - we have it in the endpoint.
            //sendAcct.Production_Salesforce_Id__c = thisOrgAcctId;
    
            //serialize our single account record and send it back!
            String jsonStr = json.serialize(sendAcct);
            system.debug(jsonStr);
    
            return jsonStr;
        }
    
        public String getMasterTestIdFromSandbox(Id thisMTId) {
            String strEndpoint = tr.instance_url + '/' + 'services/data/v40.0/query/?q=';
            strEndpoint+= 'SELECT+Id+from+Master_Test__c+WHERE+Production_Salesforce_Id__c+=+\'' + thisMTId + '\'+LIMIT+1';
    
            Http hQuery = new Http();
            HttpRequest reqQuery = new HttpRequest();
            reqQuery.setHeader('Content-Type','application/json');
            reqQuery.setHeader('Accept', 'application/json');
            reqQuery.setHeader('Authorization', 'Bearer ' + tr.access_token);
            reqQuery.setEndpoint(strEndpoint);
            reqQuery.setMethod('GET');
            reqQuery.setTimeout(100000);
    
            //HttpResponse resQuery = hQuery.send(reqQuery);
            HttpResponse resQuery = sendRequest(reqQuery, '{"totalSize":1,"done":true,"records":[{"attributes":{"type":"Master_Test__c","url":"/services/data/v40.0/sobjects/Master_Test__c/' + thisMTId + '"},"Id":"' + thisMTId + '"}]}');
            hClsResult objResult = (hClsResult)JSON.deserialize(resQuery.getBody(), hClsResult.class);
            

            List<Master_Test__c> mtList = (List<Master_Test__c>)objResult.records;
            Master_Test__c myMT = mtList[0];

            String returnId;
            try {
                returnId = myMT.Id;
            } catch (Exception e) {}
            return returnId;
        }

        /** NOT USED
        public List<String> getSkipFields(String objName) {
            List<String> skipFields = new List<String>();
            if(objName == 'Quota__c'){
                skipFields.add('related_test__c');
                skipFields.add('sandbox_salesforce_id__c');
                skipFields.add('production_salesforce_id__c');
            }

            return skipFields;
        }
         */

        //get list of every editable/insertable field on an object.
        //if there are some fields you want to manually add to the query or skip over; add to the skipFields list.
        public List<String> editableFields(String sObjectName, List<String> skipFields) {
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sObjectName.toLowerCase());
            List<String> fieldNames = new List<String>();
    
            Map<String, Schema.SObjectField> fieldMap = targetType.getDescribe().fields.getMap();
            for(String fieldName : fieldMap.keySet()) {
                //system.debug(fieldName + ': ' + fieldMap.get(fieldName).getDescribe().isUpdateable());
                //system.debug(fieldMap.get(fieldName).getDescribe());
                
                if(fieldMap.get(fieldName).getDescribe().isUpdateable()) {
                    if(!skipFields.contains(fieldName)) {
                        fieldNames.add(fieldName);
                    }
                }
            }
            system.debug(fieldNames);
            return fieldNames; 
        }

        /** Moved to UtilityMethods class
          * public List<String> fieldSetFields(String sObjectName) {
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sObjectName.toLowerCase());
            system.debug('DC: FS: ' + targetType);
          
            List<String> fieldNames = new List<String>();
            Set<String> fieldSetNames = new Set<String>();

            //Get ALL the fields from the object
            Map<String, Schema.SObjectField> fieldMap = targetType.getDescribe().fields.getMap();
            system.debug('DC: FS: ' + fieldMap);

            //Get ALL the fields that are in the fieldset...
            Schema.FieldSet objFieldSet = targetType.getDescribe().fieldSets.getMap().get('CopyMasterTest');
            system.debug('DC: FS: ' + objFieldSet);

            //Loop through the fieldset and add those field names to a set...
            for(Schema.FieldSetMember f : objFieldSet.getFields()) {
                fieldSetNames.add(f.getFieldPath());
            }
            system.debug('DC: FS: ' + fieldSetNames);

            //Loop through the fieldset set... and then check that that field is editable
            //for(String fieldName : fieldMap.keySet()) {
            for(String fieldName : fieldSetNames) {
                system.debug('DC: FS: ' + fieldName);
                try {         
                    //Check that the field is editable, if so - add to the final list.
                    //01.15.2021 - can't use the is editable... that check is respecting user permissions; 
                    //even though this class is without sharing.  And if someone copies down a test, we want to make sure
                    //EVERYTHING goes over!  Not just the stuff they have access to.
                    //The field sets will need to exclude read-only fields or formula fields.  
                    //system.debug('DC: FS: ' + fieldMap.get(fieldName).getDescribe().isUpdateable());
                    //if(fieldMap.get(fieldName).getDescribe().isUpdateable() || sObjectName == 'Opportunity') {
                        fieldNames.add(fieldName);
                    //}
                } catch (Exception e) {
                    System.debug('DC: Issue with fieldName: ' + fieldName);
                }
            }
            return fieldNames; 
        }*/

        public void addResponseToMsg(String msgType, HttpResponse hr) {
            String statusCode = String.valueOf(hr.getStatusCode());
            if(statusCode.left(1) == '2') {
                statusMessages += msgType + ': <b>Success</b>';
                statusMessages += '<br/>';
            } else {
                statusMessages += msgType + ': <b>Error</b> ' + hr.getStatus() + ' (' + statusCode + ')';
                statusMessages += '<br/>';
                doContinue = false;
            }
            if(statusCode.left(1) != '2') {
                statusMessages += hr.getBody();
                statusMessages += '<br/>';
            }
        }
        
        public void addStringToMsg(String msg) {
            statusMessages += msg;
            statusMessages += '<br/>';
        }

        public HttpResponse sendRequest(HttpRequest req, String fakedJson) {
            HttpResponse response;
            Http httpProtocol = new Http();
            if(!Test.isRunningTest()) {
                response = httpProtocol.send(req);
                System.debug('DC: sendRequest BODY: ' + response.getBody());
                System.debug('DC: sendRequest FakedJson: ' + fakedJson);
            } else {
                response = new HttpResponse();
				response.setStatus('OK');
                response.setStatusCode(200);
                response.setBody(fakedJson);
            }
            return response;
        }

        //////////////////////////////////
        // INNER / HELPER CLASSES
        //////////////////////////////////
    
        public class TokenResponse{
            public String access_token {get; set;}
            public String instance_url {get;set;}
        }

        public class hClsResult {
            public List<sObject> records {get;set;}
        }

        public class hClsQuery {
            public String hasErrors {get;set;}
            public List<hClsResults> results {get; set;}
        }

        public class hClsResults {
            public String referenceId {get; set;}
            public String id {get; set;}
        }
    }