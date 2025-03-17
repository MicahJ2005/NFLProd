trigger TriggerFramework_Test_Respondent on Test_Respondent__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
/**
*   {Purpose}  �  Wrapper trigger for all functions on Test_Respondent__c
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name                    Description
*   20140819    Andy Boettcher DCS      Created
*   20201014    Sophia Murphy (Demand Chain)
*               Added in call to setExpressTester; see DC Case 8823
*   20220707    Sophia Murphy DCS       Added enable/disable flag
*   20240214    Sophia Murphy (Demand Chain)
*               Added call to EngagementBatch_Utility to create transactions records
*               for Qualified or Disqualified records
*   =============================================================================
*/

    Map<String, Boolean> mapAPEXSettings = UtilityMethods.CODE_SETTINGS();
    
    if(mapAPEXSettings.get('enableTestRespondentTrigger')) {
        //09.28.2021 - Sophia Murphy (Demand Chain)
        //  Added in limit check
        if(Limits.getQueries() < 90) {
            if(trigger.isBefore) {

                ///////////////////////////
                // Pull Donation Information from Contact
                ///////////////////////////
                if(trigger.isInsert) {

                    Set<Id> setContactIds = new Set<Id>();
                    for(Test_Respondent__c tr : trigger.new) {
                        setContactIds.add(tr.Respondent__c);
                    }

                    Map<Id, Contact> mapContact = new Map<Id, Contact>([
                        SELECT Organization1__c, Donation_Amount_Per_Event__c FROM Contact WHERE Id IN :setContactIds
                    ]);

                    for(Test_Respondent__c tr : trigger.new) {
                        if(mapContact.containsKey(tr.Respondent__c)) {
                            tr.Organization__c = mapContact.get(tr.Respondent__c).Organization1__c;
                            tr.Donation_Amount_Per_Event__c = mapContact.get(tr.Respondent__c).Donation_Amount_Per_Event__c;
                        }
                    }
                }

                // Some stupid platform limit that prevents the deletion of any TR with more than 200 TRQs
                if(trigger.isDelete) {
                    List<Test_Respondent_Quota__c> lstTRQ = [SELECT Id FROM Test_Respondent_Quota__c WHERE Test_Respondent__c IN :trigger.oldMap.keyset()];
                    if(lstTRQ.size() > 0) { delete lstTRQ; }
                }
            } //END: if(trigger.isBefore)

            if(trigger.isAfter){

                UtilityMethods.LOG_MESSAGE('TR Trigger After START', '');

                ///////////////////////////
                // Amazon SQS
                ///////////////////////////
                if(!UtilityMethods.bolPreventTRSQS) {
                    UtilityMethods.sendSAPITriggerWrapper('FPITestRespondent');
                }

                // Handle Email Logging
                if(trigger.isUpdate) {
                    TestRespondentLibrary.processTriggeredTREmails(trigger.oldMap, trigger.newMap);
                }
                
                if(trigger.isInsert || trigger.isUpdate)
                {
                    TestRespondentHandler.setPrimaryHousehold(trigger.oldMap, trigger.newMap);
                    //CASE 8823 - Demand Chain
                    System.debug('DC: calling setExpress Tester');
                    TestRespondentHandler.setExpressTester(trigger.newMap);
                    EngagementBatch_Utility.createRespondentTransactions(trigger.oldMap, trigger.newMap);
                }

                if(trigger.isInsert || trigger.isUpdate || trigger.isDelete) {

                    Boolean bolSendContactSQS = false;

                    ///////////////////////////
                    // Contact Rollups - NEW
                    ///////////////////////////
                    if(mapAPEXSettings.containsKey('Contact-Respondent-ReportingDates') && !UtilityMethods.bolPreventContactRollup && Limits.getQueries() < 95) {
                        if(mapAPEXSettings.get('Contact-Respondent-ReportingDates')) {

                            Set<Id> setContactIdsForRollup = new Set<Id>();

                            if(trigger.isInsert || trigger.isUpdate) {
                                for(Test_Respondent__c objTR : trigger.new) {
                                    if(objTR.Respondent__c != null) { setContactIdsForRollup.add(objTR.Respondent__c); }
                                }
                            }

                            if(trigger.isDelete) {
                                for(Test_Respondent__c objTR : trigger.old) {
                                    if(objTR.Respondent__c != null) { setContactIdsForRollup.add(objTR.Respondent__c); }
                                }
                            }

                            if(setContactIdsForRollup.size() > 0) {
                                bolSendContactSQS = true;
                                UtilityMethods.bolPreventContactSQS = true;
                                ContactLibrary.rollupSummaryDates(setContactIdsForRollup, true);
                            }
                        }
                    }

                    ///////////////////////////
                    // Contact Rollups - ORIGINAL
                    ///////////////////////////
                    if(mapAPEXSettings.get('ContactRollups') && !UtilityMethods.bolPreventContactRollup) {

                        Set<String> setTestedStatusScope = new Set<String>();
                        setTestedStatusScope.add('Tested');
                        setTestedStatusScope.add('PSA');
                        setTestedStatusScope.add('Cancelled');
                        setTestedStatusScope.add('Canceled');
                        setTestedStatusScope.add('No Show');
                        setTestedStatusScope.add('Disqualified - Paid');
                        setTestedStatusScope.add('Additional Tested');
                        //02.27.2019 - need to add "Tardy Not Paid"
                        setTestedStatusScope.add('Tardy Not Paid');

                        Set<Id> setContactIds = new Set<Id>();

                        if(trigger.isInsert){
                            for(Test_Respondent__c tr:trigger.new){
                                if(setTestedStatusScope.contains(tr.Tested_Status__c)) {
                                    setContactIds.add(tr.Respondent__c);
                                }
                            }
                        }

                        if(trigger.isUpdate){
                            for(Test_Respondent__c tr:trigger.new){
                                if(setTestedStatusScope.contains(tr.Tested_Status__c) && (tr.Tested_Status__c != trigger.oldMap.get(tr.Id).Tested_Status__c)) {
                                    setContactIds.add(tr.Respondent__c);
                                }
                            }
                        }

                        if(setContactIds.size() > 0) {
                            bolSendContactSQS = true;
                            UtilityMethods.bolPreventContactSQS = true;
                            //NO LONGER NEEDED
                            //ContactLibrary.rollupSummary(setContactIds); 
                        }

                    }

                    ///////////////////////////
                    // Quant-Qual 
                    ///////////////////////////
                    if(mapAPEXSettings.containsKey('Contact-Respondent-Reporting') && !UtilityMethods.bolPreventContactRollup) {
                        if(mapAPEXSettings.get('Contact-Respondent-Reporting')) {

                            Set<String> setTestedStatusScope = new Set<String>();
                            setTestedStatusScope.add('Additional Tested');
                            setTestedStatusScope.add('Tested');

                            Set<Id> setTRScopeIds = new Set<Id>();

                            if(trigger.isDelete) {
                                for(Test_Respondent__c tr : trigger.old) {
                                    if(setTestedStatusScope.contains(tr.Tested_Status__c)) { setTRScopeIds.add(tr.Id); }
                                }
                            } else if(trigger.isUpdate) {
                                for(Test_Respondent__c tr : trigger.new) {
                                    if(setTestedStatusScope.contains(tr.Tested_Status__c) && !setTestedStatusScope.contains(trigger.oldMap.get(tr.Id).Tested_Status__c)) { setTRScopeIds.add(tr.Id); }
                                }
                            } else if(trigger.isInsert) {
                                for(Test_Respondent__c tr : trigger.new) {
                                    if(setTestedStatusScope.contains(tr.Tested_Status__c)) { setTRScopeIds.add(tr.Id); }
                                }
                            }

                            if(setTRScopeIds.size() > 0) {
                                bolSendContactSQS = true;
                                UtilityMethods.bolPreventContactSQS = true;
                                ContactLibrary.rollupQuantQual(setTRScopeIds);
                            }

                        }
                    }

                    ///////////////////////////
                    // Pull all results and send SQS
                    ///////////////////////////

                    if(bolSendContactSQS) {
                        if(trigger.isInsert || trigger.isUpdate) {
                            //03.08.2024 - this should be FPITestRespondent too right?  We're not sending contacts?
                            //UtilityMethods.sendSAPIWrapper('FPIRespondent', 'update', trigger.newMap.keyset(), false);
                            UtilityMethods.sendSAPIWrapper('FPITestRespondent', 'update', trigger.newMap.keyset(), false);
                        }
                        if(trigger.isDelete) {
                            //1.21.2022 - Valtira says this needs to send to FPITestRespondent - not FPIRespondent
                            //UtilityMethods.sendSAPIWrapper('FPIRespondent', 'delete', trigger.oldMap.keyset(), false);
                            UtilityMethods.sendSAPIWrapper('FPITestRespondent', 'delete', trigger.oldMap.keyset(), false);
                        }
                    }
                }
            } //END: if(trigger.isAfter)
        } //END: if(Limits.getQueries() < 90)
    }
}