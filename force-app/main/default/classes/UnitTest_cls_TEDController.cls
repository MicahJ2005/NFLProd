@isTest
//09.20.2018    Sophia Murphy (Demand Chain)
//              Updated to use record type ids, not set by name
public class UnitTest_cls_TEDController {
    @isTest
	static void doNothing(){
        TEDexport_Controller.doNothing();
	}
    /**
@isTest
    private static void testCQrecordType(){
        //Setup an Account, Opportunity, and Master Test
        Account acctTest = UnitTest_Test_Data.buildTestAccount('Eurofins Client', Userinfo.getUserId()); 
        insert acctTest;
        
		Opportunity oppTest = UnitTest_Test_Data.BuildOpportunity(acctTest.Id,'Consumer Research Opportunity', 'Approved'); 
        insert oppTest;
		
		Master_Test__c mtTest = UnitTest_Test_Data.BuildMasterTest();
		mtTest.Opportunity__c = oppTest.Id;
		insert mtTest;
        
        Test.startTest();
            //create the field entries that will auto-create the Case Queues
            Id objCQRT = Schema.SObjectType.Task_Queue__c.getRecordTypeInfosByName().get('Fielding Test Summary').getRecordTypeId();

            Task_Queue__c objCQ = new Task_Queue__c();
            //objCQ.RecordType.Name = 'Field Test Summary'; //record type 'Field Test Summary'
            objCQ.RecordTypeId = objCQRT;
        	objCQ.Master_Test__c = mtTest.Id;
        	objCQ.Prep_Trial_in_Bid__c = True;

        insert objCQ;
            //create the task object 'product inventory'
            Id objRT = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Product Inventory').getRecordTypeId();

            Task objT = new Task();
            //objT.RecordType.Name = 'Product Inventory';
            objT.RecordTypeId = objRT;
            objT.FPI_Code__c = '111';
            objT.Rotation_Description__c = '2% milk';

        insert objT;

        List<Task> tTasks = [SELECT
                        Id,
                        FPI_Code__c,
                        Rotation_Description__c
                    FROM Task
                    //WHERE RecordTypeId = '012U00000009ycGIAQ'
                    WHERE RecordTypeId = :objRT];

        List<Task_Queue__c> cTasks = [SELECT
                                        Id,
                                        Prep_Trial_in_Bid__c
                                        FROM Task_Queue__c
                                        //WHERE RecordTypeId = '012U00000009ycGIAQ'
                                        WHERE RecordTypeId = :objCQRT
                                        ];
        //test to see if the values are as expected.
        System.assertEquals(True, objCQ.Prep_Trial_in_Bid__c);
        System.assertEquals(objT.FPI_Code__c,'111');
        System.assertEquals(objT.Rotation_Description__c,'2% milk');
        Test.stopTest();
    }
    */
}