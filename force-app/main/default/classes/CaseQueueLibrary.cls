public with sharing class CaseQueueLibrary {
/**
*   {Purpose}  �  Code Library for the Task_Queue__c object
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name                    Description
*   20140822    Andy Boettcher DCS      Created
*   20141009    Becky Miller - FPI      Updated the Subject Line
*	20180711	Jeff Johnson - FPI		updated the fields converted
*   20221128    Sophia Murphy DC        Updated so articulation score copy can look at the contactId or the caseQueue
*   =============================================================================
*/
    private final sObject soObject;

    ///////////////////////////
    // Constructors
    ///////////////////////////
    public CaseQueueLibrary(ApexPages.StandardController scController) {
        // TODO
        this.soObject = (sObject)scController.getRecord();
    }
    
    
    ///////////////////////////
    // GET / SET
    ///////////////////////////
    
    ///////////////////////////
    // Action Methods
    ///////////////////////////
    /** REMOVED - PCCs are no longer used
    public PageReference convertToOppPCC() {

        Task_Queue__c tq = [SELECT Id,Name,Status__c, Type__c, MT_PCC_Amount__c, Description__c, Master_Test__r.Opportunity__c, //Amount__c,
                                Client_Contact__c, Client_Approval__c, Discount__c, Test_Admin_del__c, Vendor_Partners_del__c,
                            Expenses__c, Incentive_del__c, Total_CSD_Estimated_hours__c, Total_Recruiting_Estimated_hours__c,
                            Total_PM_Estimated_hours__c, Total_Fielding_Office_Estimated_hours__c, Total_Stats_Estimated_hours__c, 
                            Total_Fielding_Site_Estimated_hours__c, Total_Steam_Estimated_hours__c, CQ_PCC_Net_Test_Admin__c, CQ_PCC_Pass_Thru__c,
                            PCC_Cost_of_Sales__c, CQ_PCC_Gross_Margin_Dollar__c,Vendor_Partner_Margined__c
                                FROM Task_Queue__c 
                                WHERE Id = :this.soObject.Id];

        Project_Change_Control__c pccNew = new Project_Change_Control__c();
        pccNew.Opportunity__c = tq.Master_Test__r.Opportunity__c;//good
        pccNew.Client_Contact__c = tq.Client_Contact__c;//not needed
        pccNew.Client_Approval__c = tq.Client_Approval__c;//we can create this to pipe over, however in practice, there will be a PB to update the approval on the corresponding CQ
        pccNew.Change_Details__c = tq.Description__c;//good
        pccNew.Status__c = tq.Status__c;//good
        pccNew.Type__c = tq.Type__c;//good
        pccNew.Amount__c = tq.MT_PCC_Amount__c;//good
        pccNew.Subject__c = tq.Name;//good
        pccNew.Total_CSD_Estimated_hours__c = tq.Total_CSD_Estimated_hours__c;//good
        pccNew.Total_Recruiting_Estimated_hours__c = tq.Total_Recruiting_Estimated_hours__c;//good
        pccNew.Total_PM_Estimated_hours__c = tq.Total_PM_Estimated_hours__c;//good
        pccNew.Total_Fielding_Office_Estimated_hours__c = tq.Total_Fielding_Office_Estimated_hours__c;//good
        pccNew.Total_Stats_Estimated_hours__c = tq.Total_Stats_Estimated_hours__c;//good
        pccNew.Total_Fielding_Site_Estimated_hours__c = tq.Total_Fielding_Site_Estimated_hours__c;//good
        pccNew.Total_Steam_Estimated_hours__c = tq.Total_Steam_Estimated_hours__c;//good
        pccNew.Test_Admin__c = tq.Test_Admin_del__c;// added5/25/18
        pccNew.Discount__c = tq.Discount__c;// added5/25/18
        pccNew.Expenses__c = tq.Expenses__c;// added 11/5/18
        pccNew.Incentives__c = tq.Incentive_del__c;// added5/25/18
        pccNew.Vendor_Partners__c = tq.Vendor_Partner_Margined__c;// added 11/21/18
        pccNew.PCC_Cost_of_Sales__c = tq.PCC_Cost_of_Sales__c;// added5/25/18
        pccnew.Case_Queue_PCC__c = tq.Id; //added 6/12/18
        System.Debug(pccNew);
        insert pccNew;

        PageReference prPCC = new PageReference('/' + tq.Master_Test__r.Opportunity__c);
        prPCC.setRedirect(true);
        return prPCC;


    }
    */

    public PageReference convertToArticulation() {

        Task objTask = (Task)this.soObject;

        Task_Queue__c objTaskQueue;
        Contact objContact;

        System.debug('DC: objTask: ' + objTask);
        System.debug('DC: objTaskQueue: ' + objTaskQueue);
        System.debug('DC: objContact: ' + objContact);
        
        try {
            objTaskQueue = [SELECT Contact_Name__c FROM Task_Queue__c WHERE Id = :objTask.WhatId];
        } catch (Exception e) {}

        System.debug('DC: objTask: ' + objTask);
        System.debug('DC: objTaskQueue: ' + objTaskQueue);
        System.debug('DC: objContact: ' + objContact);

        try {
            objContact = [SELECT Id FROM Contact WHERE Id = :objTask.WhoId];
        } catch (Exception e) {}

        System.debug('DC: objTask: ' + objTask);
        System.debug('DC: objTaskQueue: ' + objTaskQueue);
        System.debug('DC: objContact: ' + objContact);

        if(objContact == null && objTaskQueue != null) {
            objContact = new Contact(Id=objTaskQueue.Contact_Name__c);
        }

        System.debug('DC: objTask: ' + objTask);
        System.debug('DC: objTaskQueue: ' + objTaskQueue);
        System.debug('DC: objContact: ' + objContact);
        
        objContact.Final_Articulation_Score__c = objTask.Final_Articulation_Score__c;
        objContact.Creativity_Score__c = objTask.Creativity_Score__c;
        objContact.Last_Articulated_Date__c = objTask.LastModifiedDate.date();
        objContact.Notes_on_Restriction__c = objTask.Notes_on_Restriction__c;

        UtilityMethods.bolPreventContactRollup = true;
        update objContact;
        UtilityMethods.bolPreventContactRollup = false;

        PageReference prContact = new PageReference('/' + objContact.Id);
        prContact.setRedirect(true);
        return prContact;

    }
    
    
    ///////////////////////////
    // Inner / Helper Classes
    ///////////////////////////
}