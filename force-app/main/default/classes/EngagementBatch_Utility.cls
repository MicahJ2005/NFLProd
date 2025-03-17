/**
* Referenced by the other "EngagementBatch_**" files
* and triggers that create the transaction records
* 
* @Date: 	02.09.2024
* @Author: 	Sophia Murphy (Demand Chain)
*
* Change Log
* ---------------------------------------------------
* 02.14.2024    Sophia Murphy (Demand Chain)
*               Methods for creating transactions
* 
*/
public with sharing class EngagementBatch_Utility {
    public EngagementBatch_Utility() {

    }

    //Called from TriggerFramework_Contact
    public static void createReferralTransactions(Map<Id, Contact> oldMap, Map<Id, Contact> newMap) {
        List<EngagementTransaction__c> eTransList = new List<EngagementTransaction__c>();
        List<Contact> contactList = new List<Contact>();

        Boolean isInsert = false;
        if(oldMap == null) {
            isInsert = true;
        }

        for(Id cId : newMap.keySet()) {
            Contact newResp = newMap.get(cId);
            Contact oldResp;
            if(!isInsert) {
                oldResp = oldMap.get(cId);
            }

            //Is_Referral? UNCHECKED means that the referred person SIGNED UP, if it's checked - they were referred, but haven't signed up yet
            //
            if(newResp.Is_Referral__c == false && newResp.Referred_By__c != null) {
                if(isInsert || oldResp.Is_Referral__c == true || oldResp.Referred_By__c != newResp.Referred_By__c) {
                    contactList.add(newResp);
                }
            }
        } //END: for(Id cId : newMap.keySet())

        for(Contact cnt : contactList) {
            EngagementTransaction__c et = new EngagementTransaction__c();
            et.AmountEarned__c = getAmount('Engagement_ReferralAmount');
            et.Category__c = 'Referral';
            et.EngagementProfile__r = new EngagementProfile__c(External_ID__c = cnt.Referred_By__c);
            et.External_ID__c = 'Refer-' + cnt.Id;
            et.TransactionDate__c = cnt.CreatedDate;
            et.Notes__c = 'Respondent referred ' + cnt.FirstName + ' ' + cnt.LastName + ' (PID: ' + cnt.PID__c + ')';
            eTransList.add(et);
        }
        if(eTransList.size() > 0) {
            upsert eTranslist External_ID__c;
        }
    }
    //Called from TriggerFramework_Contact
    public static void createProfileSurveyTransactions(Map<Id, Contact> oldMap, Map<Id, Contact> newMap) {
        List<EngagementTransaction__c> eTransList = new List<EngagementTransaction__c>();
        List<Contact> contactList = new List<Contact>();

        Boolean isInsert = false;
        if(oldMap == null) {
            isInsert = true;
        }

        for(Id cId : newMap.keySet()) {
            Contact newResp = newMap.get(cId);
            Contact oldResp;
            if(!isInsert) {
                oldResp = oldMap.get(cId);
            }

            if(newResp.Last_Profile_Sweeper_Update__c != null) {
                if(isInsert || oldResp.Last_Profile_Sweeper_Update__c != newResp.Last_Profile_Sweeper_Update__c) {
                    contactList.add(newResp);
                }
            }
        } //END: for(Id cId : newMap.keySet())

        for(Contact cnt : contactList) {
            EngagementTransaction__c et = new EngagementTransaction__c();
            et.AmountEarned__c = getAmount('Engagement_ProfileSurveyAmount');
            et.Category__c = 'Profile Survey';
            et.EngagementProfile__r = new EngagementProfile__c(External_ID__c = cnt.Id);
            et.External_ID__c = cnt.Id + '-' + cnt.Last_Profile_Sweeper_Update__c.year();
            et.TransactionDate__c = cnt.Last_Profile_Sweeper_Update__c;
            //et.Notes__c = 'Respondent completed the profile survey';
            eTransList.add(et);
        }
        if(eTransList.size() > 0) {
            upsert eTranslist External_ID__c;
        }
       
    }
    //Called from TriggerFramework_Test_Respondent
    //Looks to see if the status changed to Qualified or Disqualified
    public static void createRespondentTransactions(Map<Id, Test_Respondent__c> oldMap, Map<Id, Test_Respondent__c> newMap) {
        List<EngagementTransaction__c> eTransList = new List<EngagementTransaction__c>();
        List<Test_Respondent__c> trList_Qualified = new List<Test_Respondent__c>();
        List<Test_Respondent__c> trList_Disqualified = new List<Test_Respondent__c>();

        Boolean isInsert = false;
        if(oldMap == null) {
            isInsert = true;
        }

        for(Id trId : newMap.keySet()) {
            Test_Respondent__c newResp = newMap.get(trId);
            Test_Respondent__c oldResp;
            if(!isInsert) {
                oldResp = oldMap.get(trId);
            }

            if(newResp.Master_Test_Engagement_Amount__c > 0 && newResp.Respondent__c != null) {
                if(newResp.Respondent_Status__c == 'Qualified' && (isInsert || oldResp.Respondent_Status__c != 'Qualified')) {
                    trList_Qualified.add(newResp);
                }
                if(newResp.Respondent_Status__c == 'Scheduled' && (isInsert || oldResp.Respondent_Status__c != 'Scheduled')) {
                    trList_Qualified.add(newResp);
                }
                if(newResp.Respondent_Status__c == 'Disqualified' && (isInsert || oldResp.Respondent_Status__c != 'Disqualified')) {
                    trList_Disqualified.add(newResp);
                }
            }
        } //END: for(Id trId : newMap.keySet())

        for(Test_Respondent__c tr : trList_Qualified) {
            EngagementTransaction__c et = new EngagementTransaction__c();
            et.AmountEarned__c = tr.Master_Test_Engagement_Amount__c;
            et.Category__c = 'Qualified';
            et.EngagementProfile__r = new EngagementProfile__c(External_ID__c = tr.Respondent__c);
            et.External_ID__c = 'TR-' + tr.Id;
            et.TransactionDate__c = tr.Engagement_Date__c;
            et.Notes__c = 'Respondent qualified for ' + tr.Master_Test_Project_Number__c + ' (ID: ' + tr.Master_Test__c + ')';
            eTransList.add(et);
        }
        for(Test_Respondent__c tr : trList_Disqualified) {
            EngagementTransaction__c et = new EngagementTransaction__c();
            et.AmountEarned__c = tr.Master_Test_Engagement_Amount__c;
            et.Category__c = 'Disqualified';
            et.EngagementProfile__r = new EngagementProfile__c(External_ID__c = tr.Respondent__c);
            et.External_ID__c = 'TR-' + tr.Id;
            et.TransactionDate__c = tr.Engagement_Date__c;
            et.Notes__c = 'Respondent disqualified for ' + tr.Master_Test_Project_Number__c + ' (ID: ' + tr.Master_Test__c + ')';
            eTransList.add(et);
        }
        if(eTransList.size() > 0) {
            upsert eTranslist External_ID__c;
        }
        
    }

    public static String getLastRunDate() {
        DateTime lastRunDate = FPI_AppSettings__c.getValues('EngagementBatch_LastProcessDate').Value_DateTime__c;
        if(lastRunDate == null) {
            lastRunDate = DateTime.now().addDays(-1);
        }
        String strLastRunDate = lastRunDate.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        return strLastRunDate;
    }

    public static Decimal getAmount(String csName) {
        String batchSize_String;
        Decimal batchSize_Decimal = .05;
        try {
            batchSize_String = FPI_AppSettings__c.getValues(csName).Value__c;
            batchSize_Decimal = Decimal.valueOf(batchSize_String);

            if(batchSize_Decimal == null || batchSize_Decimal < 0) {
                batchSize_Decimal = .05;    //Default?  5cents?
            }
        } catch (Exception e) {}
        return batchSize_Decimal;
    }

    public static Integer getBatchSize(String csName) {
        String batchSize_String;
        Integer batchSize_Integer = 100;
        try {
            batchSize_String = FPI_AppSettings__c.getValues(csName).Value__c;
            batchSize_Integer = Integer.valueOf(batchSize_String);

            if(batchSize_Integer == null || batchSize_Integer < 0 || batchSize_Integer > 200) {
                batchSize_Integer = 100;
            }
        } catch (Exception e) {}
        return batchSize_Integer;
    }

    public static Boolean jobsAreRunning() {
        //Checks to see if any of the EngagementBatch jobs are running - if they are - we don't want to start these

        Boolean retVal = true;

        List<AsyncApexJob> jobs = new List<AsyncApexJob>([SELECT ID, Status, JobType, MethodName, ApexClass.Name 
                                        FROM AsyncApexJob 
                                        WHERE (ApexClass.Name = 'EngagementBatch_ContactProfiles'
                                                OR ApexClass.Name = 'EngagementBatch_Transactions'
                                                OR ApexClass.Name = 'EngagementBatch_TestRespondents'
                                                OR ApexClass.Name = 'EngagementBatch_ProcessRecalcs')
                                        AND JobType = 'BatchApex'
                                        AND Status = 'Processing']);
        if(jobs.size() < 1) {
            //None are running...
            retVal = false;
        }

        return retVal;
    }
}