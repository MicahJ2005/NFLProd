public with sharing class EmailMessageMethods {
    
    public static void CreateTaskQueue(list<EmailMessage> lstEmailMessages){
        set<Id> setCaseIds = new set<Id>();
        list<Task> lstNewTask = new list<Task>();
        string name;    
        for(EmailMessage emess: lstEmailMessages){
            String parentId = emess.ParentID;
            //10.24.2022 - Sophia Murphy (Demand Chain)
            //Only care about the parentId if it's a Case.
            if(parentId != null && parentId != '' && parentId.substring(0,3) == '500') {
                setCaseIds.add(parentId);
            }
        }
        
        List<Task_Queue__c> lstTQs = [SELECT Case__c, Id FROM Task_Queue__c WHERE Case__c in :setCaseIds];

        //02.27.2019 - Sophia Murphy (Demand Chain)
        //  If the Case Record Type is "Commercial Support" - don't create a task queue
        //  Case 5347 (DC)
        Map<Id, String> caseToRTMap = new Map<Id, String>();
        for(Case c : [SELECT Id, RecordType.Name FROM Case WHERE Id in :setCaseIds])
        {
            caseToRTMap.put(c.Id, c.RecordType.Name);
        }

        for(EmailMessage em: lstEmailMessages){

            String parentId = em.ParentID;
            
            String rtName = caseToRTMap.get(em.ParentID);
            if(rtName != 'Commercial Support') {
                    //if it's commercial support we don't want to do any of the below.
                if(em.subject == null) {
                    em.subject = ' ';
                }
                
                if(em.subject.length() > 50){
                    //12.18.2018 - Sophia - Updated to 0,50 from 0,59
                    name = em.Subject.substring(0,50);
                }
                else {
                    name=em.Subject;
                } //END: if(em.subject.length() > 50)

                if(lstTQs.size() == 0 && (parentId != null && parentId != '' && parentId.substring(0,3) == '500') ){
                //Create Task Queue and link it to the case
                        Task_Queue__c newTQ = new Task_Queue__c(
                                        Case__c  = em.ParentId,
                                        Description__c = em.TextBody,
                                        Name = name
                        );
                        insert newTQ;
                        
                        Task newTask = new Task(
                                            Subject = name,
                                            Description = em.TextBody,
                                            WhatId = newTQ.Id,
                                            EmailID__c = em.Id
                        );
                        insert newTask;
                } //END: if(lstTQs.size() == 0)

                for(Task_Queue__c tq: lstTQs){
                    if(em.ParentId == tq.Case__c){
                        Task newTask = new Task(
                                            Subject = name,
                                            Description = em.TextBody,
                                            WhatId = tq.Id,
                                            EmailID__c = em.Id
                        );
                        insert newTask;
                    }
                } //END: for(Task_Queue__c tq: lstTQs)
            } //END: if(rtName != 'Commercial Support')
        } //END: for(EmailMessage em: lstEmailMessages)

       
    } //END: public static void CreateTaskQueue
}