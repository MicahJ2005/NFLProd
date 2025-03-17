trigger TriggerFramework_ProjChangeControl on Project_Change_Control__c (after delete, after insert, after undelete, after update) {
/**
* {Purpose} trigger for all functions on the Project Change control object - all business logic is to be placed in referenced
*classes and only routing logic is to be created here.
*
* {Author} Jeff Johnson
*	Covance Food Solutions - DBA Food Perspectives.
* */
/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date          Name              Description
*   20180409    Jeff Johnson FPI    Created
*   =============================================================================
*/
  /**
     if(trigger.isAfter) {
       
      if(trigger.isInsert || trigger.isUpdate) {
        ProjectChangeControlLibrary.PCCupdate(trigger.new);
      }
         
         if(trigger.isDelete) {
             ProjectChangeControlLibrary.PCCupdate(trigger.old);
         }
         
    }
      */
     
}