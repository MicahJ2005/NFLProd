public with sharing class TestExecutionDetailManagerController {
/**
*   {Purpose}  �  TODO:  Provide Purpose
*
*   {Contact}   - jjohnson@foodperspectives.com
*                 763-354-7840                 
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   YYYYMMDD  	FN LN FPI				Created
*	20170117	Jeff Johnson	
*	20171129	Jeff Johnson			adding the Activity Object in; to be able to add multiple products at the same time on the TED page.
*   =============================================================================
*/
public static void doNothing() {}

/** Commented out - TED is no longer used
    public Id idRecord {get;set;}
    public ApexPages.StandardController scMain {get;set;}
    public Task_Queue__c objAVIT {get;set;}
    public Task_Queue__c objFTS {get;set;} //FTS stands for Field Test Summary
    public Task_Queue__c objInventory {get;set;}
    public Task_Queue__c objTER {get;set;} // TER stands for Test Event Request
    public Task_Queue__c objIHUT {get;set;}
    public List<Task_Queue__c> lstTQLinks {get;set;}
    public Task tskNew {get;set;}
    public Master_Test__c objMT {get;set;}
    //Public List<Task> lstInv {get;set;}
	Public List<Task> lstTasks {get;set;}//added 20171129
  	//find the label name of the record type so we can use it later
    private Id tskrecordTypeId = Task.SObjectType.getDescribe().getRecordTypeInfosByName().get('Product Inventory').getRecordTypeId();  
    
    public TestExecutionDetailManagerController (ApexPages.StandardController fpController){
        idRecord = fpController.getId();
        scMain = fpController;
        	instanciateInventoryTask();
			lstTasks=New List<Task> ();
        	//lstInv=New List<Task> ();

        retrieveTQLinks();
        retrieveCaseQueues();
        retrieveInventoryTasks();
        
    }
    ////////////////////////////
	// Action Methods
	///////////////////////////
    public void retrieveCaseQueues() {
        objAVIT = findOrCreateCaseQueue('AV/IT');
        objFTS = findOrCreateCaseQueue('Fielding Test Summary');
        objInventory = findOrCreateCaseQueue('Inventory');
        objTER = findOrCreateCaseQueue('Test Events Request');
        objIHUT = findOrCreateCaseQueue('IHUT');

    }
//query for all the fields in Task with a record type of "Product Inventory", so we can use them later.     
    private void retrieveInventoryTasks() {
       		//find the label name of the record type so we can use it later
        //Id TskrecordTypeId = Task.SObjectType.getDescribe().getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        
        lstTasks = new List<Task>();
        
        if(objFTS.Id != null) {
            lstTasks = [SELECT
                            Id,
                            Subject,
                            Exp_Date_or_Use_By_Date__c,
                            Exp_or_Use_By_Date_2__c,
                            Exp_or_Use_By_Date_3__c,
                            Exp_or_Use_By_Date_4__c,
                            Exp_or_Use_By_Date_5__c,
                        	Expected_Storage_State__c,
                        	Expected_Arrival_State__c,
                        	FPI_Code__c,                 
                            Lot_Plant_Code__c,
                            ProductInformation__c,
                            Product_Label_Detail__c,
                        	Product_Package_Dimensions__c,
                        	Product_Package_Weight__c,
                        	Product_Pre_Coded__c,
                            Post_Test_Product_Handling__c,
                        	Post_Test_Product_Handling_Other__c,
                            //Product_Arrival__c,
                            Quantity_Damaged_Destroyed__c,
                        	Req_Product_Size__c,
                        	Req_Use_By_Date__c,
                        	Req_Lot_Code__c,
                        	Requested_Qty__c,
                        	Rotation_Description__c,
                        	Size__c,
                            Total_Quantity_Received__c,
                            Total_Qty_Recvd_2__c,
                            Total_Qty_Recvd_3__c,
                            Total_Qty_Recvd_4__c,
                            Total_Qty_Recvd_5__c,
                        	UPC_Code__c,
                        	Who_Will_Procure__c
                        FROM
                            Task
                        WHERE
                            WhatId = :objFTS.Id
                        	And Recordtypeid = :tskrecordTypeId
                       ];
        }
        System.Debug('objFTS.ID = ' + objFTS.Id);
        System.Debug(lstTasks.size());
    }
    
    //
    public void instanciateInventoryTask() {
		tskNew = new Task(
        	RecordTypeId = tskrecordTypeId
        );     
    }

//get the link for the Task Queue (aka Case Queue) this is what is populated at the top of the page IF Case Queues exist.
    public void retrieveTQLinks() {
        lstTQLinks = [SELECT Id, Name FROM Task_Queue__c WHERE Master_Test__c = :idRecord ORDER BY RecordType.Name, Name];
    }
 
//create a new Task Queue if the record type doesn't exist. 
    public Task_Queue__c findOrCreateCaseQueue(String recordTypeName) {
        
        Task_Queue__c objCQ;
        
		//find the label name of the record type so we can use it later
        Id recordTypeId = Task_Queue__c.SObjectType.getDescribe().getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        
		//query for all the fields in Task_Queue__c regardless of record type, so we can use them later.
        List<Task_Queue__c> lstCQ = [SELECT 
                                        Id, 
                                        Name, 
                                        Additional_Client_Names__c, 
                                     	Audio_Visual_IT_Equipment_Notes__c,
                                        Client_Arrival_Time__c, 
                                        Client_Meal_Preference__c, 
                                        Client_Pre_Order_Meal__c, 
                                        Client_Provided_Codes__c,
                                        Client_Provided_Procurement_Details__c, 
                                        Does_Client_want_Prep_Trial__c, 
                                        Equipment_Needs__c,
                                        Equipment_Needs_Other__c,
                                     	Estimated_Shipping_Box_Weight__c,
                                     	FG_PO_Moderator__c,
                                        How_many__c, 
                                     	How_Many_Ipads_Are_Needed__c,
                                        Is_IHUT_Applicable__c, 
                                        Lead_Client__c,
                                        //Lead_Client_Lookup__c,
                                        Live_Streaming__c,                                    
                                        Number_of_codes__c,
                                        Number_of_panels__c,
                                        Number_of_Products_Per_Panel__c,
                                        Package_Dimensions__c, 
                                        Package_Weight__c,
                                        Party_providing_printed_inserts__c,
                                        Peel_Off_Focus_Group_Info__c, 
                                        Peel_Off_Focus_Group_Planned__c, 
                                        PO_FG_add_on__c,
                                        PO_FG_add_on_Other__c,
                                        PO_FG_Supplies__c,
                                        PO_FG_Supplies_Add_tl_Setup__c,
                                     	PO_FG_Supplies_Other__c,
                                        Post_Test_Product_Handling__c, 
                                        Post_Test_Product_Handling_Other__c, 
                                        Prep_Trial_details__c,
                                     	Prep_Trial_in_Bid__c,
                                        Prep_Trial_Preference__c, 
                                        Printed_Insert_information__c,                                    
                                        //Product_Arrival__c, 
                                        Product_Arrival_Other__c,
                                        Product_Arrival_Temp__c, 
                                        Product_Codes_Provided_by__c, 
                                        Product_delivery_date__c, 
                                        Product_Package_Dimensions__c,                                     
                                        Product_Pre_Coded__c,
                                     	Product_Prep_Instructions__c,
                                        Product_Storage__c, 
                                        Product_Storage_Other__c, 
                                        Product_Storage_Temp__c,
                                     	Product_Arriving_Pre_Coded__c,
                                     	//FPI_Code__c,
                                        Qty_Expected_Per_Code__c,
                                        Real_Time_Reporting__c,
                                        Recording_Rooms__c,
                                        Recruit_ship_per_panel__c,
                                        PT_Return_Product_To__c,
                                        Return_Product_To_other__c,
                                        Rotation_plan__c,
                                        Rotation_Plan_Other__c, 
                                     	Standard_Equipment_Needs__c,
                                     	Serving_Container__c,
                                     	Serving_Container_Other__c,
                                     	Serving_Utensil__c,
                                     	Serving_Utensil_Other__c,
                                     	Serving_Carriers__c,
                                     	Serving_Size__c,
                                        Shipping_Equipment__c,
                                        Special_Equipment__c,
                                     	Special_Equipment_Needs__c, 
                                     	Testing_Location_Rooms__c,
                                        Type_of_delivery_service__c, 
                                        Type_of_delivery_service_Other__c, 
                                        Type_of_delivery_vehicle__c, 
                                        Type_of_delivery_vehicle_Other__c,
                                        What_Equipment_Is_Needed__c, 
                                        //Who_Will_Procure__c, 
                                        Will_Additional_Clients_Be_Attending__c, 
                                        Will_Clients_be_attending__c,
                                     	Clients_on_Site__c,
                                        First_Date_Needed__c, 
                                        Last_Date_Needed__c,
                                     	Client_Meal_1__c, 
                                     	Client_Meal_2__c, 
                                     	Client_Meal_3__c, 
                                     	Client_Meal_4__c
                                    FROM 
                                        Task_Queue__c 
                                    WHERE 
                                        RecordTypeId = :recordTypeId 
                                        AND Master_Test__c = :idRecord
                                    ORDER BY 
                                        CreatedDate ASC
        ];
        
        // If the list is NOT empty, take the first record - otherwise instantiate a new record.
        if(!lstCQ.isEmpty()) {
            objCQ = lstCQ[0];
            System.Debug('USING EXISTING CASE QUEUE FOR ' + recordTypeName + ' OF ID ' + objCQ.Id);
        } else {
            //create a new Case Queue object from the fielding page, name it with the label name of the record type and link it to the Master Test
            objCQ = new Task_Queue__c(
                Name = 'Auto - ' + recordTypeName,
                Master_Test__c = idRecord, 
                RecordTypeId = recordTypeId
            );
            System.Debug('CREATING NEW CASE QUEUE FOR ' + recordTypeName + '!');
        }
        
        return objCQ;
    }          
    //the Save button will save all fields in each record type... 
    public void saveCaseQueues() {
        upsert objAVIT;
        upsert objFTS;
        upsert objTER;
        upsert objIHUT;
        for(task tsk:lstTasks){
            tsk.whatId=objFTS.Id;
        }
        update lstTasks;
        scMain.save();
    }
    //the Add new Inventory button will add all fields in each record type...
    public void AddNewInventory(){
        insert tskNew;
        lstTasks.add(tskNew);
        instanciateInventoryTask();
        
        // Just to be safe...protect against CLICKY CLICKY users!
        saveCaseQueues();
    }

    //export the TED page.... this needs to be just a reference to the template doc uploaded to SF.... 
    Public PageReference TEDexport(){
        return Page.TED_Export_Sec_Pick;
    }
    //notify the Ops team 
    public void NotifyTeam(){
        
    }
    */
          
}