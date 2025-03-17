/**
 * @description       : Controller for MasterQuotaDatatable 
 * @testclass(s)      : MasterQuotaDatatableControllerTest (100%)
 *
 * @author            : Matthew J Lennington
 * @group             : Demand Chain
 * @last modified on  : 2024-02-19
 * @last modified by  : Matthew J Lennington
 * @change            :
 *
*/
public with sharing class MasterQuotaDatatableController {
    
    /**
     * @description : returns all the Quota__c records for a Related_Test__c record
     * 
     * @param recordId : Related_Test__c Id
     * @return List<Quota__c>
     *
     * @author Matthew J Lennington -- (Demand Chain)
     * @date 2024-02-19
     *
    */
    @AuraEnabled(cacheable=true)
    public static List<Quota__c> getMasterQuota(Id recordId) {
        return [SELECT Id, Name, Quota_Summary__c, Beacon_Condition__c, Minimum_Respondents__c, Maximum_Respondents__c,
        Tested_Goal__c, IsOpen__c, IsScheduleEnabled__c, IsTrackingOnly__c, Fill_Weighting__c, MQG__c FROM Quota__c WHERE Related_Test__c =: recordId];
    }

     /**
     * @description : Saves a List of Quota__c
     * 
     * @param records : List<Quota__c>
     *
     * @author Matthew J Lennington -- (Demand Chain)
     * @date 2024-02-19
     *
    */
    @AuraEnabled
    public static void save(List<Quota__c> records) {
        update records;
    }
}