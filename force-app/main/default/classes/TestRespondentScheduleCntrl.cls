public with sharing class TestRespondentScheduleCntrl {
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
*   20160329    Jason Flippen DCS       Refactored the scheduleRespondentWorker
*                                       method to be bulkified.  Original method
*                                       has been commented out.
*   =============================================================================
*/
    public Id idRespondent {get;set;}
    private Test_Respondent__c objTR {get;set;}
    public Id idMasterTest {get;set;}
    public Id idSession {get;set;}
    public Boolean bolArticulationNeeded {get;set;}
    public String strStatusOverride {get;set;}
    public List<hClsSession> lstSessions {get;set;}
    public List<hClsQuota> lstHard {get;set;}
    public List<hClsQuota> lstSoft {get;set;}
    private Set<Id> setSelectedSessions = new Set<Id>();
    private Set<Id> setSelectedQuotas = new Set<Id>();

    ///////////////////////////
    // Constructors
    ///////////////////////////
    public TestRespondentScheduleCntrl(ApexPages.StandardController scController) {
        idRespondent = scController.getId();
        objTR = (Test_Respondent__c)scController.getRecord();
        
        for(Test_Respondent__c tr : [SELECT Master_Test__c FROM Test_Respondent__c WHERE Id = :idRespondent]) {
            idMasterTest = tr.Master_Test__c;
        }
        for(Test_Respondent_Quota__c trq : [SELECT Session_Quota__c, Session_Quota__r.Related_Session__c 
                                                FROM Test_Respondent_Quota__c 
                                                WHERE Test_Respondent__c = :idRespondent
                                                    AND IsQualified__c = true]) {
            setSelectedQuotas.add(trq.Session_Quota__c);
            setSelectedSessions.add(trq.Session_Quota__r.Related_Session__c);
        }

        bolArticulationNeeded = false;
        fillSessions();
        fillQuotas();
    }

    ///////////////////////////
    // GET / SET
    ///////////////////////////
    public List<SelectOption> lstStatus {
        get {
            List<SelectOption> lstTemp = new List<SelectOption>();
            lstTemp.add(new SelectOption('Prequalified','Prequalified'));
            lstTemp.add(new SelectOption('Scheduled','Scheduled'));
            return lstTemp;
        }
    }

    ///////////////////////////
    // Action Methods
    ///////////////////////////
    public void fillSessions() {

        lstSessions = new List<hClsSession>();

        String strQuery = 'SELECT ';
        for(Schema.FieldSetMember fsm : SObjectType.Session__c.FieldSets.RespondentSchedule.getFields()) {
            strQuery+= fsm.getFieldPath() + ', ';
        }
        strQuery+= 'Id FROM Session__c WHERE Related_Test__c = :idMasterTest AND Linked_Session__c = null ORDER BY Session_Start__c';
        
        for(Session__c ses : (List<Session__c>)Database.query(strQuery)) {
            lstSessions.add(new hClsSession(setSelectedSessions.contains(ses.Id), ses));
        }

    }

    public void fillQuotas() {

        lstHard = new List<hClsQuota>();
        lstSoft = new List<hClsQuota>();

        if(idSession == null) { return; }

        // Identify default Schedule Status
        Session__c seStatus = [SELECT IsArticulationNeeded__c FROM Session__c WHERE Id = :idSession];
        strStatusOverride = 'Scheduled';
        if(seStatus.IsArticulationNeeded__c) {
            strStatusOverride = 'Prequalified';
        }

        String strQuery = 'SELECT ';
        for(Schema.FieldSetMember fsm : SObjectType.Session_Quota__c.FieldSets.RespondentSchedule.getFields()) {
            strQuery+= fsm.getFieldPath() + ', ';
        }
        strQuery+= 'Id, Master_Quota__r.IsTrackingOnly__c FROM Session_Quota__c WHERE Related_Session__c = :idSession ORDER BY Beacon_Condition__c';

        for(Session_Quota__c sq : (List<Session_Quota__c>)Database.query(strQuery)) {
            if(sq.Master_Quota__r.IsTrackingOnly__c) {
                lstSoft.add(new hClsQuota(setSelectedQuotas.contains(sq.Id), sq));
            } else {
                lstHard.add(new hClsQuota(setSelectedQuotas.contains(sq.Id), sq));
            }
        }
    }
    
    public PageReference scheduleRespondent() {

        scheduleRespondentWorker(idRespondent, true);

        System.Debug('***********');

        PageReference prRef = new PageReference('/' + idRespondent);
        prRef.setRedirect(true);
        return prRef;

    }

    private void scheduleRespondentWorker(Id idTargetRespondent, Boolean bolRunCancelLogic) {

        Set<Id> setTargetRespondentId = new Set<Id>();
        setTargetRespondentId.add(idTargetRespondent);

        // Get TR Ids for Pairs
        for (Test_Respondent__c trPair : [SELECT Id
                                          FROM   Test_Respondent__c
                                          WHERE  Pair_Primary__c = :idTargetRespondent]) {
            setTargetRespondentId.add(trPair.Id);
        }
        System.debug('*** setTargetRespondentId: ' + setTargetRespondentId);

        // Step 1:  Remove all previous schedule instances
        if (bolRunCancelLogic) {

            Set<Id> setCancelSessionIds = new Set<Id>();
            for (Test_Respondent_Quota__c trq : [SELECT Id,
                                                       Session_Quota__r.Related_Session__c
                                                FROM   Test_Respondent_Quota__c
                                                WHERE  Test_Respondent__c IN :setTargetRespondentId]) {
                setCancelSessionIds.add(trq.Session_Quota__r.Related_Session__c);
            }

            Map<Id, Session__c> mapCancelSessions = new Map<Id, Session__c>([SELECT Id
                                                                             FROM   Session__c
                                                                             WHERE  Id IN :setCancelSessionIds]);
            // Replaced 20141020 AAB - Bulkification on Cancellation
            if (mapCancelSessions.size() > 0) {
                Test_Respondent__c trMaster = new Test_Respondent__c(Id=idRespondent);
                MasterTestLibrary.cancelRespondentFromSession(trMaster, mapCancelSessions.keySet());
            }
        }
        
        // Step 2:  Add to new SQs

        List<Test_Respondent_Quota__c> lstTRQInsert = new List<Test_Respondent_Quota__c>();
        if (!setTargetRespondentId.isEmpty()) {

            System.Debug('PROCESSING SOFT QUOTAS');

            for (hClsQuota clsQ : lstSoft) {
                if (clsQ.bolChecked) {
                    for (Id targetRespondentId : setTargetRespondentId) {
                        System.Debug('CREATING TRQ FOR ' + clsQ.sq.Id + ' AS ' + strStatusOverride);
                        Test_Respondent_Quota__c trqNew = new Test_Respondent_Quota__c();
                        trqNew.Test_Respondent__c = targetRespondentId;
                        trqNew.Session_Quota__c = clsQ.sq.Id;
                        trqNew.IsQualified__c = true;

                        if (strStatusOverride == 'Prequalified') { 
                            trqNew.IsPreQualified__c = true;
                        } else {
                            trqNew.IsScheduled__c = true;
                        }

                        lstTRQInsert.add(trqNew);
                    }

                } // End If (clsQ.bolChecked)

            } // End For (hClsQuota clsQ : lstSoft)


            System.Debug('PROCESSING HARD QUOTAS');

            for (hClsQuota clsQ : lstHard) {
                if (clsQ.bolChecked) {
                    for (Id targetRespondentId : setTargetRespondentId) {
                        System.Debug('CREATING TRQ FOR ' + clsQ.sq.Id + ' AS ' + strStatusOverride);
                        Test_Respondent_Quota__c trqNew = new Test_Respondent_Quota__c();
                        trqNew.Test_Respondent__c = targetRespondentId;
                        trqNew.Session_Quota__c = clsQ.sq.Id;
                        trqNew.IsQualified__c = true;

                        if (strStatusOverride == 'Prequalified') { 
                            trqNew.IsPreQualified__c = true;
                        } else {
                            trqNew.IsScheduled__c = true;
                        }

                        lstTRQInsert.add(trqNew);
                    }

                } // End If (clsQ.bolChecked)

            } // End For (hClsQuota clsQ : lstHard)

            System.Debug('INSERTING ' + lstTRQInsert.size() + ' TRQs');
            
            if (lstTRQInsert.size() > 0) { 
                insert lstTRQInsert; 
                System.Debug(lstTRQInsert);
            }

            for (Id targetRespondentId : setTargetRespondentId) {
                //Updating scheduleLinkedSessions to a future method - does multiple DMLs in a for loop
                //10.01.2021 - Sophia Murphy (Demand Chain)
                //MasterTestLibrary.scheduleLinkedSessions(new Test_Respondent__c(Id=targetRespondentId), new Session__c(Id=idSession));
                MasterTestLibrary.scheduleLinkedSessions(targetRespondentId, idSession);
            }

        } // End If (!setTargetRespondentId.IsEmpty())

    }
    
    ///////////////////////////
    // Inner / Helper Classes
    ///////////////////////////
    public class hClsSession {
        public Boolean bolSelected {get;set;}
        public Session__c ses {get;set;}
        public hClsSession(Boolean passSelected, Session__c passSession) {
            bolSelected = passSelected;
            ses = passSession;
        }
    }

    public class hClsQuota {
        public Boolean bolChecked {get;set;}
        public Session_Quota__c sq {get;set;}
        public hClsQuota(Boolean passChecked, Session_Quota__c passSQ) {
            bolChecked = passChecked;
            sq = passSQ;
        }
    }
}