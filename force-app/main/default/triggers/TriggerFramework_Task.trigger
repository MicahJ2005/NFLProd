trigger TriggerFramework_Task on Task (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {

		if(trigger.isAfter){
			if(trigger.isUpdate || trigger.isInsert){
				TaskMethods.UpdateArticulationScore(trigger.new);
			}
		}
}