//02.04.2020 - removed fields that have no data.
public with sharing class ShippingInfo_Controller {
	public static void doNothing() {}
	/** Commented out - no longer in use 
	public Task_Queue__c tskQ {get;set;}
    //public Task_Queue__c tskM {get;set;}	
    private id idMT;
	public ShippingInfo_Controller(ApexPages.StandardController stdController) {
        Try{
            //this.tskQ = (Task_Queue__c)stdController.getRecord();
            //this.idMT = stdController.getRecord().getSObjectType().getDescribe().getName();
		// STEP 1:  PULL ID FROM STANDARDCONTROLLER
            String objectName = UtilityMethods.findObjectNameFromRecordIdPrefix(stdController.getId());
            
            if(objectName == 'Task_Queue__c') {
                this.tskQ = (Task_Queue__c)stdController.getRecord();
                String tqId = this.tskQ.Id;
		tskQ = [SELECT Id
						,Project_Name__c
						,Delivery_Date__c
                		,Location__r.Shipping_Information__c
						,Location__r.ShippingStreet
						,Location__r.ShippingCity
						,Location__r.ShippingState
						,Location__r.ShippingPostalCode
						,Location__r.ShippingCountry
						,Location__r.Name
						,(SELECT Id
									,Delivery_Date__c //This field is going away
									,Qty_Expected_Per_Code__c
									,Product_Package_Dimensions__c
									,Product_Package_Weight__c
									,Expected_Arrival_State__c //This field is going away
									,Expected_Storage_State__c //replace this with 'Product_Storage__c'
									,Product_Pre_Coded__c //I think we need to change this to a 'yes/no' option instead of free text
                          			//,Product_Code__c //this will change to 'Product_Code__c'
									,Rotation_Description__c
                          			,FPI_Code__c
									,Expected_Product_Quantity__c
							FROM Tasks
							)
					FROM Task_Queue__c 
					WHERE Id = :tqId];
                    }else if(objectName == 'Master_Test__c') {
                idMT = stdController.getId();
        }
        }catch(exception ex){
        }
                this.idMT = stdController.getId();
    }*/
}