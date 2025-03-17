trigger TriggerFramework_EmailMessage on EmailMessage (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {

/**
*   {Purpose}  �  Wrapper trigger for all functions on EmailMessage - all business logic is to be placed in referenced
*				classes and only routing logic is to be created here.
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20140519  	Matt Smelser DCS		Created
*   =============================================================================
*/

	if(trigger.isInsert && trigger.isAfter){
		EmailMessageMethods.CreateTaskQueue(trigger.new);		
	}

}