public with sharing class MasterTestLibrary {
/**
*   {Purpose}  �  TODO:  Host centralized functions for Master Tests and Scheduling
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name                    Description
*   20140703    Andy Boettcher DCS      Created
*   20140904    Andy Boettcher DCS      Added logic in computeQuotaFillRates to only add
*                                       counts to Session from Primary Quotas
*   20160329    Jason Flippen DCS       Refactored the scheduleLinkedSessions
*                                       method to not contain DML inside Loops.
*                                       Original method had been commented out.
*   20160705    Andy Boettcher DCS      Changed scheduleRespondentForSession to account for ALL Quotas,
*                                       not just open.
*   20160711    Jason Flippen DCS       Modified SyncAssumptionsFromQuote method to make sure the current
*                                       User exists and has a UserLicense of "Salesforce" before processing.
*   20240405    Sophia Murphy DChain    Updates on how Pairs-Multi-Day tests are handled
*   =============================================================================
*/

    public static Boolean checkForOpenQuotaSet(Test_Respondent__c trRespondent, Session__c seSession) {

        Boolean bolRetValue = true;

        Map<Id, Test_Respondent_Quota__c> mapTRQs = new Map<Id, Test_Respondent_Quota__c>([
            SELECT
                Id,
                Session_Quota__r.IsOpen__c,
                Session_Quota__r.IsMasterOpen__c
            FROM
                Test_Respondent_Quota__c
            WHERE
                Test_Respondent__c = :trRespondent.Id
                AND IsQualified__c = true
                AND Session_Quota__r.Related_Session__c = :seSession.Id
        ]);

        for(Test_Respondent_Quota__c trq : mapTRQs.values()) {
            if(!trq.Session_Quota__r.IsOpen__c || !trq.Session_Quota__r.IsMasterOpen__c) {
                bolRetValue = false;
            }
        }

        return bolRetValue;

    }

    public static Boolean scheduleRespondentForSession(Test_Respondent__c trRespondent, Session__c seSession) {

        Boolean bolRetValue = false;

        // Find all SQs for the Session Provided
        //Map<Id, Session_Quota__c> mapSQs = new Map<Id, Session_Quota__c>([
        //    SELECT Id FROM Session_Quota__c WHERE Related_Session__c = :seSession.Id
        //        AND IsOpen__c = true AND IsMasterOpen__c = true]);

        /*** CHANGE 20160705 AAB - Removing filter to only schedule for OPEN Quotas ***/
        Map<Id, Session_Quota__c> mapSQs = new Map<Id, Session_Quota__c>([
            SELECT Id FROM Session_Quota__c WHERE Related_Session__c = :seSession.Id]);

        // Find all TRQs for the provided session that the TR qualified for
        Map<Id, Test_Respondent_Quota__c> mapTRQs = new Map<Id, Test_Respondent_Quota__c>([
            SELECT Id, IsScheduled__c, IsPreQualified__c, Session_Quota__r.Related_Session__r.IsArticulationNeeded__c
            FROM Test_Respondent_Quota__c WHERE Test_Respondent__c = :trRespondent.Id
                AND IsQualified__c = true AND Session_Quota__c IN :mapSQs.keySet()]);

        // Mark TRQs as Scheduled!
        for(Test_Respondent_Quota__c trq : mapTRQs.values()) {
            if(trq.Session_Quota__r.Related_Session__r.IsArticulationNeeded__c) {
                trq.IsPreQualified__c = true;
            } else {
                trq.IsScheduled__c = true;
            }
        }

        if(mapTRQs.size() > 0) {
            bolRetValue = true;
            update mapTRQs.values();
        } else {
            bolRetValue = false;
            return bolRetValue;
        }

        //////////////////////////////////
        // Handle Parent/Child Sessions
        //////////////////////////////////
        // Make sure that Related_Test__c is on this Session Object
        
        //10.1.2021 - Sophia Murphy (Demand Chain)
        //Updated scheduleLinkedSessions to be a future method; need to just accept IDs not objects.
        //Session__c seMaster = [SELECT Id, Related_Test__c FROM Session__c WHERE Id = :seSession.Id LIMIT 1];
        //scheduleLinkedSessions(trRespondent, seMaster);
        scheduleLinkedSessions(trRespondent.Id, seSession.Id);

        //////////////////////////////////
        // Update TR with info passed from FPITesters
        //////////////////////////////////
        update trRespondent;

        //////////////////////////////////
        // Send all TRs via SQS
        //////////////////////////////////
        Set<Id> setTRIds = new Set<Id>();
        setTRIds.add(trRespondent.Id);

        for(Test_Respondent__c tr : [SELECT Id FROM Test_Respondent__c WHERE Session_Id__c = :seSession.Id]) {
            setTRIds.add(tr.Id);
        }

        UtilityMethods.sendSAPIWrapper('FPITestRespondent', 'update', setTRIds);

        // Compute Quotas
        //MasterTestLibrary.computeQuotaFillRates(mapTRQs.keySet());

        return bolRetValue;
    }

    //10.1.2021 - Sophia Murphy (Demand Chain)
    //Updated scheduleLinkedSessions to be a future method; need to just accept IDs not objects.
    //public static void scheduleLinkedSessions(Test_Respondent__c trRespondent, Session__c seMasterSession) {
    @future
    public static void scheduleLinkedSessions(Id trId, Id sessionId) {

        // This method creates "dummy" tracking MQs and SQs, creates dupe TRs and sticks in child sessions.
        Session__c seMasterSession = [SELECT Id, Related_Test__c FROM Session__c WHERE Id = :sessionId];
        Master_Test__c mtTest = [SELECT Id, Target_Respondent__c FROM Master_Test__c WHERE Id = :seMasterSession.Related_Test__c LIMIT 1];
        //04.05.2024 - Need to add Pair_Primary__c; Scheduler_Contact_ID__c into this clone!
        Test_Respondent__c trTest = [SELECT Id, Master_Test__c, Respondent__c, Respondent_Status__c, Tested_Status__c, Screener_Results__c 
                                        , Pair_Primary__c, Scheduler_Contact_ID__c
                                        FROM Test_Respondent__c WHERE Id = :trId];

        // Find all Linked Sessions
        Map<Id, Session__c> mapLinkedSessions = new Map<Id, Session__c>([SELECT Id,
                                                                                IsArticulationNeeded__c
                                                                         FROM   Session__c
                                                                         WHERE  Linked_Session__c = :seMasterSession.Id]);

        // If no sessions, return.
        if (mapLinkedSessions.size() > 0) {
            System.Debug('STARTING LINKED INNER LOGIC');

            // Verify that a Linked Session MQ exists
            //If this is NOT a child; OR NOT a multi-day pairs test - then we use this kind of quota
            // If it's a pairs test; but this is the ADULT - then use the regular quota
            Quota__c mqLinked;
            if((mtTest.Target_Respondent__c != 'Adult-Kid Pairs' && mtTest.Target_Respondent__c != 'Adult-Adult Pairs') || trTest.Pair_Primary__c == null) {
                List<Quota__c> lstMQLinked = [SELECT Id
                                            FROM   Quota__c
                                            WHERE  Related_Test__c = :mtTest.Id
                                            AND    Quota_Summary__c = 'Linked Session Tracking Quota'];

                if (lstMQLinked.size() == 0) {
                    mqLinked = new Quota__c();
                    mqLinked.Related_Test__c = mtTest.Id;
                    mqLinked.Quota_Summary__c = 'Linked Session Tracking Quota';
                    mqLinked.IsOpen__c = true;
                    //setting the Min and Max to 0 is closing the quota once 1 person signs up.
                    //Should we set these to 999?  does that mess up the instance rate calcs?
                    mqLinked.Minimum_Respondents__c = 0;
                    mqLinked.Maximum_Respondents__c = 0;
                    mqLinked.IsTrackingOnly__c = false;
                    mqLinked.IsScheduleEnabled__c = false;
                    insert mqLinked;
                } else {
                    mqLinked = lstMQLinked[0];
                }
            }

            //If this is ALSO a PAIRS test - we need a Linked Session tracking Quota (Pair) for the PAIRED person.
            Quota__c mqLinkedPairs;
            if((mtTest.Target_Respondent__c == 'Adult-Kid Pairs' || mtTest.Target_Respondent__c == 'Adult-Adult Pairs') && trTest.Pair_Primary__c != null) {
                List<Quota__c> lstMQLinkedPairs = [SELECT Id
                                          FROM   Quota__c
                                          WHERE  Related_Test__c = :mtTest.Id
                                          AND    Quota_Summary__c = 'Linked Session Tracking Quota (Pairs)'];

                if (lstMQLinkedPairs.size() == 0) {
                    mqLinkedPairs = new Quota__c();
                    mqLinkedPairs.Related_Test__c = mtTest.Id;
                    mqLinkedPairs.Quota_Summary__c = 'Linked Session Tracking Quota (Pairs)';
                    mqLinkedPairs.IsOpen__c = true;
                    mqLinkedPairs.Minimum_Respondents__c = 0;
                    mqLinkedPairs.Maximum_Respondents__c = 0;
                    mqLinkedPairs.IsTrackingOnly__c = true; //THIS SHOULD BE TRUE - THIS ONE IS a Secondary Quota
                    mqLinkedPairs.IsScheduleEnabled__c = false;
                    insert mqLinkedPairs;
                } else {
                    mqLinkedPairs = lstMQLinkedPairs[0];
                }
            }

            System.Debug('MQ PAIRS = ' + mqLinkedPairs);

            // Find Existing SQs
            Set<Id> setExistingSQs = new Set<Id>();
            if(mqLinked != null) {
                for (Session_Quota__c sq : [SELECT Id,
                                                Related_Session__c
                                            FROM   Session_Quota__c
                                            WHERE  Master_Quota__c = :mqLinked.Id]) {
                    setExistingSQs.add(sq.Related_Session__c);
                }
            }

            //Find Existing SQs on the PAIRS
            Set<Id> setExistingSQsPairs = new Set<Id>();
            if(mqLinkedPairs != null) {           
                for (Session_Quota__c sq : [SELECT Id,
                                                   Related_Session__c
                                            FROM   Session_Quota__c
                                            WHERE  Master_Quota__c = :mqLinkedPairs.Id]) {
                    setExistingSQsPairs.add(sq.Related_Session__c);
                }

            }

            // Loop through sessions and make sure SQs exist
            Set<Id> setQuotaCreate = new Set<Id>();
            if(mqLinked != null) {
                for (Session__c ses : mapLinkedSessions.values()) {
                    if (!setExistingSQs.contains(ses.Id)) {
                        setQuotaCreate.add(ses.Id);
                    }
                }
            }

            Set<Id> setQuotaCreatePairs = new Set<Id>();
            if(mqLinkedPairs != null) {
                for (Session__c ses : mapLinkedSessions.values()) {
                    if (!setExistingSQsPairs.contains(ses.Id)) {
                        setQuotaCreatePairs.add(ses.Id);
                    }
                }
            }

            // Create SQs if needed
            List<Session_Quota__c> lstInsertSQs = new List<Session_Quota__c>();
            for (Id sId : setQuotaCreate) {
                Session_Quota__c sqNew = new Session_Quota__c();
                sqNew.Master_Quota__c = mqLinked.Id;
                sqNew.Related_Session__c = sId;
                sqNew.IsOpen__c = true;
                sqNew.Maximum_Respondents__c = 0;
                sqNew.Minimum_Respondents__c = 0;
                lstInsertSQs.add(sqNew);
            }

            for (Id sId : setQuotaCreatePairs) {
                Session_Quota__c sqNew = new Session_Quota__c();
                sqNew.Master_Quota__c = mqLinkedPairs.Id;
                sqNew.Related_Session__c = sId;
                sqNew.IsOpen__c = true;
                sqNew.Maximum_Respondents__c = 0;
                sqNew.Minimum_Respondents__c = 0;
                lstInsertSQs.add(sqNew);
            }

            if (lstInsertSQs.size() > 0) { insert lstInsertSQs; }

            // Requery for new Session Quotas
            Set<Id> mqIds = new Set<Id>();
            if(mqLinked != null) {
                mqIds.add(mqLinked.Id);
            }
            if(mqLinkedPairs != null) {
                mqIds.add(mqLinkedPairs.Id);
            }
            lstInsertSQs = [SELECT Id,
                                   Related_Session__r.IsArticulationNeeded__c
                            FROM   Session_Quota__c
                            WHERE  Related_Session__c IN :mapLinkedSessions.keyset()
                            AND    Master_Quota__c IN :mqIds];

            System.Debug('QUERIES LIMIT CHECK 1 = ' + Limits.getQueries());

            List<Test_Respondent__c> lstInsertClonedTRs = new List<Test_Respondent__c>();
            Map<Id,Test_Respondent__c> mapSQtoTR = new Map<Id,Test_Respondent__c>();
            for (Session_Quota__c sq : lstInsertSQs) {
                Test_Respondent__c trClone = trTest.clone();
                lstInsertClonedTRs.add(trClone);
                mapSQtoTR.put(sq.Id,trClone);
            }
            System.debug('*** lstInsertClonedTRs: ' + lstInsertClonedTRs);

            if (lstInsertClonedTRs.size() > 0) { insert lstInsertClonedTRs; }

            System.debug('*** mapSQtoTR: ' + mapSQtoTR);

            // Create TRQ Records
            List<Test_Respondent_Quota__c> lstInsertTRQs = new List<Test_Respondent_Quota__c>();
            for (Session_Quota__c sq : lstInsertSQs) {
                if (mapSQtoTR.containsKey(sq.Id)) {
                    Test_Respondent__c testRespondent = mapSQtoTR.get(sq.Id);

                    Test_Respondent_Quota__c trqNew = new Test_Respondent_Quota__c();
                    trqNew.Test_Respondent__c = testRespondent.Id;
                    trqNew.Session_Quota__c = sq.Id;
                    trqNew.IsQualified__c = true;

                    // Mark TRQs as Scheduled!
                    if (sq.Related_Session__r.IsArticulationNeeded__c) {
                        trqNew.IsPreQualified__c = true;
                    } else {
                        trqNew.IsScheduled__c = true;
                    }

                    lstInsertTRQs.add(trqNew);
                }
            }
            System.debug('*** lstInsertTRQs: ' + lstInsertTRQs);

            if (lstInsertTRQs.size() > 0) { insert lstInsertTRQs; }
        }
    }

    public static Boolean cancelRespondentFromSession(Test_Respondent__c trRespondent, Set<Id> setSessions, Boolean bolComputeQuotas) {

        Boolean bolRetValue = cancelRespondentFromSession(trRespondent, setSessions);

        if(bolComputeQuotas) {
            Set<Id> setTRIds = new Set<Id>();
            setTRIds.add(trRespondent.Id);
            //computeQuotaFillRatesByTR(setTRIds);
        }

        return bolRetValue;

    }

    public static Boolean cancelRespondentFromSession(Test_Respondent__c trRespondent, Set<Id> setSessions) {

        Boolean bolRetValue = false;

        // Find all SQs for the Session Provided (ignore open status)
        Map<Id, Session_Quota__c> mapSQs = new Map<Id, Session_Quota__c>([
            SELECT Id FROM Session_Quota__c WHERE Related_Session__c IN :setSessions
        ]);

        if(mapSQs.size() > 0) {

            // Find all TRQs for the provided session that the TR qualified for
            Map<Id, Test_Respondent_Quota__c> mapTRQs = new Map<Id, Test_Respondent_Quota__c>([
                SELECT Id, IsScheduled__c, IsPreQualified__c FROM Test_Respondent_Quota__c WHERE Test_Respondent__c = :trRespondent.Id
                    AND (IsScheduled__c = true OR IsPreQualified__c = true) AND Session_Quota__c IN :mapSQs.keySet()]);

            // DELETE TRQs
            //if(mapTRQs.values().size() > 0) { delete mapTRQs.values(); }

            // LOGIC CHANGE - DO NOT DELETE TRQS
            for(Test_Respondent_Quota__c trq : mapTRQs.values()) {
                trq.IsScheduled__c = false;
                trq.IsPreQualified__c = false;
            }

            // UPDATE TRQ MAP
            if(mapTRQs.values().size() > 0) { update mapTRQs.values(); }

            // Cancel any Pairs
            for(Test_Respondent__c trPair : [SELECT Id FROM Test_Respondent__c WHERE Pair_Primary__c = :trRespondent.Id]) {
                cancelRespondentFromSession(trPair, setSessions);
            }

            ///////////////////////////////////////////////
            // Cancel and delete any multi-session TRs
            ///////////////////////////////////////////////

            // Get Sessions in scope
            Map<Id, Session__c> mapLinkedSessions = new Map<Id, Session__c>([
                SELECT Id FROM Session__c WHERE Linked_Session__c IN :setSessions
            ]);

            if(mapLinkedSessions.size() > 0) {

                Set<Id> setTRSiblings = new Set<Id>();
                Test_Respondent__c trSelf;
                try {
                    trSelf = [SELECT Respondent__c, Master_Test__c FROM Test_Respondent__c WHERE Id = :trRespondent.Id];
                } catch(Exception e) {}

                if(trSelf != null) {
                    Contact contParent = [SELECT Id, (SELECT Id, Session_Id__c FROM Test_Respondents__r
                    WHERE Master_Test__c = :trSelf.Master_Test__c
                            AND Id != :trRespondent.Id
                            AND Session_Id__c IN :mapLinkedSessions.keyset())
                            FROM Contact WHERE Id = :trSelf.Respondent__c];
                    for(Test_Respondent__c trSibling : contParent.Test_Respondents__r) {
                    setTRSiblings.add(trSibling.Id);
                    }

                    List<Test_Respondent__c> lstTRDelete = new List<Test_Respondent__c>([SELECT Id FROM Test_Respondent__c WHERE Id IN :setTRSiblings]);
                    if(lstTRDelete.size() > 0) { delete lstTRDelete; }
                }
            }

            bolRetValue = true;
        }

        return bolRetValue;

    }

    public static Boolean cancelRespondentFromSession(Test_Respondent__c trRespondent, Session__c seSession) {

        Boolean bolRetValue = false;

        // Reformat and send to Bulk Handler - 20140922 AAB
        Set<Id> setSessions = new Set<Id>();
        setSessions.add(seSession.Id);

        bolRetValue = cancelRespondentFromSession(trRespondent, setSessions);

        return bolRetValue;

    }

    public static void computeQuotaReportingMetrics(Set<Id> setTRIds) {

        // Get all sessions in play...
        Set<Id> setScopeTests = new Set<Id>();
        for(Test_Respondent__c objTR : [SELECT Master_Test__c FROM Test_Respondent__c WHERE Id IN :setTRIds]) {
            setScopeTests.add(objTR.Master_Test__c);
        }

        // Check to make sure we don't have any Batch jobs in "Holding" status
        if((Limits.getQueueableJobs() >= Limits.getLimitQueueableJobs()) || UtilityMethods.bolPreventMetricRollup)  {
            return;
        }

        Map<String, Boolean> mapAPEXSettings = UtilityMethods.CODE_SETTINGS();
        Map<String, String> mapAPPSettings = UtilityMethods.APP_SETTINGS();

        UtilityBatch_Metrics clsMetrics = new UtilityBatch_Metrics();
        clsMetrics.setTestIds = setScopeTests;
        clsMetrics.bolCommitCalc = mapAPEXSettings.get('BatchRecruitingRollups');

		// FORCE FIX - AAB 20181128 - CRAZY TEST, OUT OF CONTROL METRIC PROCESSOR - REMOVE AFTER REAL FIX, OH THIS IS SO BAD!
		//Set<String> setWindowedMetricExecutionTimes = new Set<String>();
		//setWindowedMetricExecutionTimes.add('0');
		//setWindowedMetricExecutionTimes.add('00');
		//setWindowedMetricExecutionTimes.add('15');
		//setWindowedMetricExecutionTimes.add('30');
		//setWindowedMetricExecutionTimes.add('45');

		//if(setWindowedMetricExecutionTimes.contains(String.valueOf(System.now().minute()))) {
			database.executeBatch(clsMetrics, Integer.valueOf(mapAPPSettings.get('MetricBatchSize')));
		//}

    }
}