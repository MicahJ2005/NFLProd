public with sharing class TaskMethods {
	public static void UpdateArticulationScore(list<Task> lstTask){
		list <Contact> lstContactUpdate = new list<Contact>();
		String strRTTask = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Articulation').getRecordTypeId();
		
		for(Task tk: lstTask){
			if(tk.WhoId != null){
				if(String.valueOf(tk.WhoId).startsWith('003') && tk.RecordTypeId == strRTTask){
					 lstContactUpdate.add( new Contact (ID = tk.WhoId, Most_Recent_Articulation_Score__c = tk.Final_Articulation_Score__c));
				}	
			}
		}
		if(lstContactUpdate.size() >0){
			update lstContactUpdate;
		}
	}
}