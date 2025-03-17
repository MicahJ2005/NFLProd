@isTest
public class TED_Page_Test {
    @isTest
	static void doNothing(){
		TestExecutionDetailManagerController.doNothing();
	}
    /** Commented out - TED is no longer used 
    @testsetup public static void setupData(){
        Master_Test__c testMT = new Master_Test__c();
        insert testMT;
        Id objCQRT = Schema.SObjectType.Task_Queue__c.getRecordTypeInfosByName().get('Fielding Test Summary').getRecordTypeId();
        Task_Queue__c testCQ = new Task_Queue__c();
        	testCQ.RecordTypeId = objCQRT; //record type 'Field Test Summary'
        	testCQ.Master_Test__c = testMT.Id;
        	testCQ.Prep_Trial_in_Bid__c = True;
        insert testCQ;
        Task testTsk = new Task();
        	Id objRT = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Product Inventory').getRecordTypeId();
        	testTsk.RecordTypeId = objRT;
            testTsk.FPI_Code__c = '111';
            testTsk.Rotation_Description__c = '2% milk';
        insert testTsk;
        
    }

    @isTest public static void TestExecutionDetailManagerControllerTest() {
		
       
        	//Test if saving on the TED page creates a Case Queue associated to a particular MT.
		Master_Test__c testMT = [select Id from Master_Test__c];
        Task_Queue__c testCQ = [select Id from Task_Queue__c];
        Task testTsk = [select Id from Task];
        
        TestExecutionDetailManagerController clsTest = new TestExecutionDetailManagerController(new ApexPages.StandardController(testMT));
        clstest.saveCaseQueues();
        clstest.AddNewInventory();
        clstest.TEDexport();
        clstest.NotifyTeam();

    }   
*/
}