/**
*   {Purpose}  Handler class off of TriggerFramework_Test_Respondent trigger
*
*   {Contact}   - support@demandchain.com
*                 www.demandchain.com  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name / Desc.
*   07/26/2018	Sophia Murphy (Demand Chain)    
*               Created
*   10/13/2020  Sophia Murphy (Demand Chain)
*               Added setExpressTester method; see DC Case 8823
*   =============================================================================
*/
public class TestRespondentHandler 
{
    //CALLED FROM AN AFTER TRIGGER - RUNS DML against the contact
    public static void setExpressTester(Map<Id, Test_Respondent__c> newMap) {	
        /** If related Master Test..
         *  Population Type = 'Express Test'
         *  Respondent Type = 'General Testing'
         * TR record is...
         * Scheduled Session != blank
         * Respondent Status = 'Scheduled'
         * THEN
         * Update the related Contact with Express Tester = TRUE
         */
        System.debug('DC: newMap: ' + newMap);
        List<Contact> cntToUpdate = new List<Contact>();
        //QUESTION: What about the Population Definition object?
        //          That object has Respondent Type; but not Population Type
        //DC CASE 10924 - added in check for Tested Status
        for(Test_Respondent__c tr : [SELECT Id, Respondent__c, Respondent__r.Express_Testing_Respondent__c, Master_Test__c
                                        FROM Test_Respondent__c
                                        WHERE Id IN :newMap.keySet()
                                        AND Scheduled_Session__c != null
                                        AND Respondent_Status__c = 'Scheduled'
                                        AND Tested_Status__c = 'Pending'
                                        AND Master_Test__r.Population_Type__c = 'Express Test'
                                        AND Master_Test__r.Respondent_Type__c = 'General Testing'
                                        AND Respondent__r.Express_Testing_Respondent__c = false]) {
                Contact c = new Contact(Id = tr.Respondent__c);
                c.Express_Testing_Respondent__c = true;
                cntToUpdate.add(c);
        }
        System.debug('DC: newMap: ' + cntToUpdate);
        if(cntToUpdate.size() > 0) {
            update cntToUpdate;
        }

    }
    //CALLED FROM AN AFTER TRIGGER - RUNS DML
    public static void setPrimaryHousehold(Map<Id, Test_Respondent__c> oldMap, Map<Id, Test_Respondent__c> newMap)  {	
        //Looking at the Respondent lookup and the Scheduler Contact Id - set the Primary Household ID
        //Could be people in multiple households, we just want one.
        
        //To start with - only run this if the Respondent, Scheduler Contact or Primary Household has changed.
        //This does NOT handle if there was a change on the Contact records.
        Map<Id, Test_Respondent__c> workingMap = new Map<Id, Test_Respondent__c>();
        Set<Id> contactIds = new Set<Id>();
        
        for(Id newId : newMap.keySet())
        {
            Test_Respondent__c oldTR;
            if(oldMap != null) 
            {
                oldTR = oldMap.get(newId);
            }
            Test_Respondent__c newTR = newMap.get(newId);
            
            if(oldTR == null 
               || oldTR.Respondent__c != newTR.Respondent__c 
               || oldTR.Scheduler_Contact_ID__c != newTR.Scheduler_Contact_ID__c  
               || oldTR.Primary_Household__c != newTR.Primary_Household__c )
            {
                workingMap.put(newId, newTR);
                if(newTR.Respondent__c != null) contactIds.add(newTR.Respondent__c);
                if(newTR.Scheduler_Contact_ID__c != null) contactIds.add(newTR.Scheduler_Contact_ID__c);
            }
        } //END: for(Id newId : newMap.keySet())
        
        //Now - get the Household Contacts tied to these!
        Map<Id, List<Household_Contact__c>> mapHouseholds = new Map<Id, List<Household_Contact__c>>();
        for(Household_Contact__c hc : [SELECT Contact__c, Household__c
                                       FROM Household_Contact__c 
                                       WHERE Contact__c IN :contactIds]) 
        {
        	List<Household_Contact__c> tmpList = mapHouseholds.get(hc.Contact__c);
            if(tmpList == null)  tmpList = new List<Household_Contact__c>();
            tmpList.add(hc);
            
            mapHouseholds.put(hc.Contact__c, tmpList);
        } //END: for(Household_Contact__c hc 
        
        //Now we have a map of Contacts to all their related Households.  
        //And we have a map of the Test Respondents.  
        List<Test_Respondent__c> trUpdates = new List<Test_Respondent__c>();
        for(Id trId : workingMap.keySet())
        {
            Test_Respondent__c tr = workingMap.get(trId);
            Test_Respondent__c newTR = new Test_Respondent__c(Id = tr.Id);
            Id respondentId = tr.Respondent__c;
            Id schedulerId = tr.Scheduler_Contact_ID__c;
            
            List<Household_Contact__c> respondentHC = mapHouseholds.get(respondentId);
            List<Household_Contact__c> schedulerHC = mapHouseholds.get(schedulerId);
            
            //If it equals exactly 1 - use it!
            if(respondentHC != null && respondentHC.size() == 1)
            {
                newTR.Primary_Household__c = respondentHC[0].Household__c;
                trUpdates.add(newTR);
            }
            else if(schedulerHC != null && schedulerHC.size() == 1)
            {
                newTR.Primary_Household__c = schedulerHC[0].Household__c;
                trUpdates.add(newTR);
            }
            else
            {
                //If we get here... then this respondent has multiple or none...
                //If the scheulder is filled in - use that one, since it means the Respondent is a minor.
                if(schedulerHC != null && schedulerHC.size() > 1)
                {
                    newTR.Primary_Household__c = schedulerHC[0].Household__c;
                	trUpdates.add(newTR);
                }
                else if(respondentHC != null && respondentHC.size() > 1)
                {
                    newTR.Primary_Household__c = respondentHC[0].Household__c;
                	trUpdates.add(newTR);
                }
                else
                {
                    //yeah... we don't know now.
                }
                
            } //END: if/else - if(respondentHC.size()
            
        } //END: for(Id trId : workingMap.keySet())
        
        if(trUpdates.size() > 0)
        {
            update trUpdates;
        }
    
    } //END: public static void setPrimaryHousehold
}