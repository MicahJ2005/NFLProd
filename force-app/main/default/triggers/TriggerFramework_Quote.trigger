trigger TriggerFramework_Quote on Quote (after delete/** , after insert, after undelete, 
after update, before delete, before insert, before update*/) {
    /** NO LONGER NEED
    if(trigger.isbefore && (trigger.isinsert || trigger.isupdate)){
    	Quote_Methods.Quote_Status_Changed(Trigger.new, Trigger.oldmap);
    }
    //updated to only call this in an AFTER update; since Quote_Status_Approved runs DML
	if(trigger.isUpdate && trigger.isAfter){
		if(!UtilityMethods.bolTriggerRecurseFlag) {
			UtilityMethods.bolTriggerRecurseFlag = true;
            Quote_Methods.Quote_Status_Approved(trigger.new);
        }
	}*/
}