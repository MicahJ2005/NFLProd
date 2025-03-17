/** 
 * Test class for all the EngagementBatch apex classes and triggers on the Engagement objects
 *
 * @Date: 	    03.12.2024
 * @Author: 	Sophia Murphy (Demand Chain)
 * 
 */
@isTest
private class EngagementBatch_TestClass 
{
	static testMethod void testMethod_Run() 
    {
        UnitTest_Test_Data.commitFPIApexSettings(true);

        //Create two respondents
            //Each should have an Engagement profile
        Contact contact1 = UnitTest_Test_Data.createRespondent();
        Contact contact2 = UnitTest_Test_Data.createRespondent();
        Contact contact3 = UnitTest_Test_Data.createRespondent();
            //FYI - there is a flow in place that should be creating a matching EngagementProfile__c record for each of these


        //One should be the referral of the other
        contact1.Referred_By__c = contact2.Id;
        contact1.Last_Profile_Sweeper_Update__c = Date.today();
        update contact1;

        Master_Test__c mt = new Master_Test__c();
        mt.Engagement_Amount__c = 10.0;
        mt.Project_Number_MT__c = '1234567';
        insert mt;

        //Create a Test Respondent records
        Test_Respondent__c tr = new Test_Respondent__c();
        tr.Respondent__c = contact1.Id;
        tr.Respondent_Status__c = 'Scheduled';
        tr.Tested_Status__c = 'Tested';
        tr.Master_Test__c = mt.Id;

        Test_Respondent__c tr2 = new Test_Respondent__c();
        tr2.Respondent__c = contact2.Id;
        tr2.Respondent_Status__c = 'Qualified';
        tr2.Tested_Status__c = 'Pending';
        tr2.Master_Test__c = mt.Id;

        Test_Respondent__c tr3 = new Test_Respondent__c();
        tr3.Respondent__c = contact3.Id; 
        tr3.Respondent_Status__c = 'Disqualified';
        tr3.Tested_Status__c = 'Pending';
        tr3.Master_Test__c = mt.Id;

        List<Test_Respondent__c> trList = new List<Test_Respondent__c>();
        trList.add(tr);
        trList.add(tr2);
        trList.add(tr3);
        insert trList;

        //Create an engagement transaction
        EngagementProfile__c ep = [SELECT Id FROM EngagementProfile__c WHERE Respondent__c = :contact1.Id LIMIT 1];
        EngagementTransaction__c et = new EngagementTransaction__c();
        et.EngagementProfile__c = ep.Id;
        et.Category__c = 'Extra';
        et.TransactionDate__c = DateTime.now();
        et.AmountEarned__c = 10.0;
        insert et;

        Test.startTest();
            EngagementBatch_ContactReferrals batchClass = new EngagementBatch_ContactReferrals(); 
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
        	System.schedule('my batch job', '0 0 0 1 1 ?', new EngagementBatch_ContactReferrals() );
		Test.stopTest();
    }
}