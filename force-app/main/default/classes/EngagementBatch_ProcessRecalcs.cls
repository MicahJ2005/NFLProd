/**
* Batch job to determine engagement profiles that need their items recalculated
*
* Schedule/run EngagementBatch_ContactReferrals
* When that finishes it will call EngagementBatch_Transactions
* When that finishes it will call EngagementBatch_TestRespondents
* When that finishes it will call EngagementBatch_ProcessRecalcs
*
* To Run from Dev Console: 
* EngagementBatch_ContactReferrals b = new EngagementBatch_ContactReferrals(); 
* database.executebatch(b, 100);
*
* Custom Settings - in FPI Application Settings that are referenced throughout the jobs
*        EngagementBatch_LastProcessDate
*        EngagementBatch_StartProcessDate
*        EngmtBatch_ContactReferrals_BatchSize
*        EngmtBatch_Transactions_BatchSize
*        EngmtBatch_TestRespondents_BatchSize
*        EngmtBatch_ProcessRecalcs_BatchSize
* 
* @Date: 	02.08.2024
* @Author: 	Sophia Murphy (Demand Chain)
*
* Change Log
* ---------------------------------------------------
* 02.09.2024    Sophia Murphy (Demand Chain)
*               Full logic for filling in all the details
* 
* 
*/
global class EngagementBatch_ProcessRecalcs implements Database.Batchable<sObject>
{
    public String query;
    
    global EngagementBatch_ProcessRecalcs() 
    {
        this.query = 'SELECT Id, External_ID__c FROM EngagementProfile__c ';
        this.query += ' WHERE Flag_for_Recalc__c = true';
        if(Test.isRunningTest())
        {
            this.query += ' LIMIT 200' ;
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) 
    {
    	return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<EngagementProfile__c> scope) 
    {
        //The KEY for the map is the Respondent Id/External Id - we need that when querying against TR records, etc.
        Map<Id, EngagementProfile__c> epMap = new Map<Id, EngagementProfile__c>();

        for(EngagementProfile__c ep : scope) {
            //Clear out/setup the profile record
            ep.AmountEarned_Lifetime__c = 0;
            ep.AmountEarned_YTD__c = 0;
            ep.AmountPaid_Lifetime__c = 0;
            ep.AmountPaid_YTD__c = 0;
            ep.Disqualified_Lifetime__c = 0;
            ep.Disqualified_YTD__c = 0;
            ep.PSA_Lifetime__c = 0;
            ep.PSA_YTD__c = 0;
            ep.Qualified_Lifetime__c = 0;
            ep.Qualified_YTD__c = 0;
            ep.Tested_Lifetime__c = 0;
            ep.Tested_YTD__c = 0;
            ep.Referred_Lifetime__c = 0;
            ep.Referred_YTD__c = 0;

            ep.LastEngagementRecalcDate__c = DateTime.now();
            ep.Flag_for_Recalc__c = false;
            epMap.put(ep.External_ID__c, ep);
        }
        epMap = calculate_engagementTransactions(epMap);
        epMap = calculate_testRespondents(epMap);
        epMap = calculate_referrals(epMap);

        if(epMap.size() > 0) {
            update epMap.values();
        }
    }

    private static Map<Id, EngagementProfile__c> calculate_referrals(Map<Id, EngagementProfile__c> epMap) {
        //Calculated from OTHER respondent records
            //Referred_Lifetime__c
            //Referred_YTD__c

        for(AggregateResult ar : [SELECT Referred_By__c
                                    , CALENDAR_YEAR(CreatedDate) engageYear
                                    , COUNT(Id) refCount
                                    FROM Contact
                                    WHERE Referred_By__c != null
                                    AND Referred_By__c IN :epMap.keySet()
                                    AND Is_Referral__c = false
                                    GROUP BY Referred_By__c, CALENDAR_YEAR(CreatedDate)]) {

            Id epKey = (Id)ar.get('Referred_By__c');
            Integer year = (Integer)ar.get('engageYear');
            Integer count = (Integer)ar.get('refCount');

            EngagementProfile__c epTemp = epMap.get(epKey);
            if(isCurrentYear(year)) {
                epTemp.Referred_YTD__c += count;
            }
            epTemp.Referred_Lifetime__c += count;

            epMap.put(epKey, epTemp);
        }
        return epMap;
    }

    private static Map<Id, EngagementProfile__c> calculate_testRespondents(Map<Id, EngagementProfile__c> epMap) {
        //Calculated from the TR records
            //Disqualified_Lifetime__c
            //Disqualified_YTD__c
            //PSA_Lifetime__c
            //PSA_YTD__c
            //Qualified_Lifetime__c
            //Qualified_YTD__c
            //Tested_Lifetime__c
            //Tested_YTD__c

        for(AggregateResult ar : [SELECT Respondent__c, Respondent_Status__c, Tested_Status__c
                                    , CALENDAR_YEAR(Engagement_Date__c) engageYear
                                    , COUNT(Id) trCount
                                    FROM Test_Respondent__c
                                    WHERE Respondent__c != null
                                    AND Respondent__c IN :epMap.keySet()
                                    AND (Respondent_Status__c IN ('Disqualified', 'Qualified', 'Scheduled') 
                                            OR Tested_Status__c IN ('Tested', 'Additional Tested', 'PSA', 'PO/FG PSA')
                                        )
                                    GROUP BY Respondent__c, Respondent_Status__c, Tested_Status__c, CALENDAR_YEAR(Engagement_Date__c)]) {

            Id epKey = (Id)ar.get('Respondent__c');
            String respStatus = (String)ar.get('Respondent_Status__c');
            String testedStatus = (String)ar.get('Tested_Status__c');
            Integer year = (Integer)ar.get('engageYear');
            Integer count = (Integer)ar.get('trCount');

            EngagementProfile__c epTemp = epMap.get(epKey);
            if(isCurrentYear(year)) {
                if(isDisQualified(respStatus, testedStatus)) {
                    epTemp.Disqualified_YTD__c += count;
                }
                if(isQualified(respStatus, testedStatus)) {
                    epTemp.Qualified_YTD__c += count;
                }
                if(isTested(respStatus, testedStatus)) {
                    epTemp.Tested_YTD__c += count;
                }
                if(isPSA(respStatus, testedStatus)) {
                    epTemp.PSA_YTD__c += count;
                }
            }

            if(isDisQualified(respStatus, testedStatus)) {
                epTemp.Disqualified_Lifetime__c += count;
            }
            if(isQualified(respStatus, testedStatus)) {
                epTemp.Qualified_Lifetime__c += count;
            }
            if(isTested(respStatus, testedStatus)) {
                epTemp.Tested_Lifetime__c += count;
            }
            if(isPSA(respStatus, testedStatus)) {
                epTemp.PSA_Lifetime__c += count;
            }

            epMap.put(epKey, epTemp);
        }
        return epMap;
    }

    private static Map<Id, EngagementProfile__c> calculate_engagementTransactions(Map<Id, EngagementProfile__c> epMap) {
        //Calculated from the Engagement Transaction Records
            //AmountEarned_Lifetime__c
            //AmountEarned_YTD__c
            //AmountPaid_Lifetime__c
            //AmountPaid_YTD__c
        for(AggregateResult ar : [SELECT EngagementProfile__r.External_ID__c extId
                                        , CALENDAR_YEAR(TransactionDate__c) engageYear
                                        , SUM(AmountEarned__c) amtEarned, SUM(AmountPaid__c) amtPaid
                                    FROM EngagementTransaction__c
                                    WHERE EngagementProfile__r.External_ID__c IN :epMap.keySet()
                                    AND EngagementProfile__r.External_ID__c != null
                                    GROUP BY EngagementProfile__r.External_ID__c, CALENDAR_YEAR(TransactionDate__c)]) {

            Id epKey = (Id)ar.get('extId');
            Integer year = (Integer)ar.get('engageYear');

            EngagementProfile__c epTemp = epMap.get(epKey);
            if(isCurrentYear(year)) {
                epTemp.AmountEarned_YTD__c += nullCheck((Decimal)ar.get('amtEarned'));
                epTemp.AmountPaid_YTD__c += nullCheck((Decimal)ar.get('amtPaid'));
            }
            epTemp.AmountEarned_Lifetime__c += nullCheck((Decimal)ar.get('amtEarned'));
            epTemp.AmountPaid_Lifetime__c += nullCheck((Decimal)ar.get('amtPaid'));
            epMap.put(epKey, epTemp);
        }
        return epMap;
    }

    private static Boolean isCurrentYear(Integer yr) {
        Boolean retVal = false;
        if(yr == DateTime.now().year()) {
            retVal = true;
        }
        return retVal;
    }
    private static Boolean isDisqualified(String rStatus, String tStatus) {
        Boolean retVal = false;
        if(rStatus == 'Disqualified') {
            retVal = true;
        }
        return retVal;
    }
    private static Boolean isQualified(String rStatus, String tStatus) {
        Boolean retVal = false;
        if(rStatus == 'Qualified' || rStatus == 'Scheduled') {
            retVal = true;
        }
        return retVal;
    }
    private static Boolean isTested(String rStatus, String tStatus) {
        Boolean retVal = false;
        if(tStatus == 'Tested' || tStatus == 'Additional Tested') {
            retVal = true;
        }
        return retVal;
    }
    private static Boolean isPSA(String rStatus, String tStatus) {
        Boolean retVal = false;
        if(tStatus == 'PSA' || tStatus == 'PO/FG - PSA') {
            retVal = true;
        }
        return retVal;
    }
    private static Decimal nullCheck(Decimal num) {
        Decimal returnVal = 0;
        if(num != null) {
            returnVal = num;
        }
        return returnVal;
    }

    global void finish(Database.BatchableContext BC) 
    {
        //Put the "start" date time into the last run date
        DateTime startDateTime = FPI_AppSettings__c.getValues('EngagementBatch_StartProcessDate').Value_DateTime__c;

        FPI_AppSettings__c lastProcessAppSetting = FPI_AppSettings__c.getInstance('EngagementBatch_LastProcessDate');
		lastProcessAppSetting.Value_DateTime__c = startDateTime;
		update lastProcessAppSetting;
    }
}