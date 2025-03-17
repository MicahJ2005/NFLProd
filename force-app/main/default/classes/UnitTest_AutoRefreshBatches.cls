/**
* UnitTest for the 3 auto refresh classes.
*
* @Date: 	11.15.2020
* @Author: 	Sophia Murphy (Demand Chain)
* 
*/
@isTest
private class UnitTest_AutoRefreshBatches 
{
	static testMethod void testMethod_Run() 
    {
        UnitTest_Test_Data.commitFPIApexSettings();

        //Create a contact/respondent
        Contact con = UnitTest_Test_Data.createRespondent();

        //Create a household and HH contact
        Household__c hshold = UnitTest_Test_Data.createHouseholdAndHouseholdContact(con.Id);

        Test.startTest();
            AutoRefreshBatch_Households batchClass = new AutoRefreshBatch_Households(); 
            Database.ExecuteBatch(batchClass, 1);
      	Test.stopTest();

    }
	static testMethod void testMethod_Schedule() 
    {
        UnitTest_Test_Data.commitFPIApexSettings();

        //Create a contact/respondent
        Contact con = UnitTest_Test_Data.createRespondent();

        //Create a household and HH contact
        Household__c hshold = UnitTest_Test_Data.createHouseholdAndHouseholdContact(con.Id);

        Test.startTest();
        	System.schedule('my batch job', '0 0 0 1 1 ?', new AutoRefreshBatch_Households() );
		Test.stopTest();
    }
}