/**
 * @description       : Batch class for updating TRs related to a particular Master Test
 * @author            : James Loghry (Demand Chain)
 * @group             : Demand Chain
 * @last modified on  : 05-07-2021
 * @last modified by  : James Loghry (Demand Chain)
 * Modifications Log
 * Ver   Date         Author                        Modification
 * 1.0   05-06-2021   James Loghry (Demand Chain)   Initial Version
**/
public class MasterTestRelatedTRQBatch implements Database.Batchable<sObject>{
    
    private Id masterTestId {get; set;}
    
    public MasterTestRelatedTRQBatch(Id masterTestId){
        this.masterTestId = masterTestId;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('Select Id From Test_Respondent_Quota__c Where Test_Respondent__r.Master_Test__c = :masterTestId');
    }
    
    public void execute(Database.BatchableContext BC,List<sObject> scope){
        Database.update(scope,false);
    }
 
   public void finish(Database.BatchableContext BC){
 
   }
}