public with sharing class DrivingDirections_Controller {
    public static void doNothing() {}
    /** Commented out all - no longer in use
	public Task_Queue__c tskQ {get;set;}
    public Task_Queue__c tskM {get;set;}
    private id idMT;
    
	public DrivingDirections_Controller(ApexPages.StandardController stdController) {
        try	{
            // STEP 1:  PULL ID FROM STANDARDCONTROLLER
            String objectName = UtilityMethods.findObjectNameFromRecordIdPrefix(stdController.getId());
            
            if(objectName == 'Task_Queue__c') {
                this.tskQ = (Task_Queue__c)stdController.getRecord();
                String tqId = this.tskQ.Id;
                        tskQ = [SELECT Id
                            ,Location__r.Driving_Directions_and_Hotel_Information__c
                            ,(SELECT Id
                                FROM Tasks
                                )
                        FROM Task_Queue__c 
                        WHERE Id = :tqId];
            } else if(objectName == 'Master_Test__c') {
                idMT = stdController.getId();
            }          
                
        } catch(exception ex) {
        
        }
        //this.idMT = stdController.getId();
        //this.idMT = stdController.getRecord().getSObjectType().getDescribe().getName();
        
	}
    public void MT_Drive (){
        List<Task_Queue__c> lstMT = [select 
                     test_location__c
                     FROM Task_Queue__c
                      WHERE Master_Test__c = :idMT AND Name = 'Auto - Fielding Test Summary'
                     ];
            tskM = lstMT[0];
    }
     */
}