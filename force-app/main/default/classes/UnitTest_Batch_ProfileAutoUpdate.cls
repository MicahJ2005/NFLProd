/**
* @Date: 	08.23.2022
* @Author: 	Sophia Murphy (Demand Chain)
*/
@isTest
private class UnitTest_Batch_ProfileAutoUpdate 
{
	static testMethod void testMethod_Run() 
    {
        UnitTest_Test_Data.commitFPIApexSettings(true);

        //Create a contact/respondent
        Contact con = UnitTest_Test_Data.createRespondent();

        //Create a household and HH contact
        Household__c hshold = UnitTest_Test_Data.createHouseholdAndHouseholdContact(con.Id);

        Master_Test__c testMasterTest = UnitTest_Test_data.BuildMasterTest();
        insert testMasterTest;

        List<FPI_AppSettings__c> appSettingsList = new List<FPI_AppSettings__c>();
        FPI_AppSettings__c testAppSetting1 = UnitTest_Test_data.BuildFPI_AppSettings('Profile_MasterTestIds', testMasterTest.Id);
        appSettingsList.add(testAppSetting1);

        //FPI_AppSettings__c testAppSetting2 = UnitTest_Test_data.BuildFPI_AppSettings('10', 'Profile_Update_BatchSize');
        //appSettingsList.add(testAppSetting2);

        //FPI_AppSettings__c testAppSetting3 = UnitTest_Test_data.BuildFPI_AppSettings('', 'Profile_TestRespondentTestIds');
        //appSettingsList.add(testAppSetting3);
        insert appSettingsList;
        

        Test_Respondent__c tr = UnitTest_Test_data.BuildTestRespondent(con.Id,testMasterTest.Id);
        tr.Screener_Results__c = buildTestScreener();
        insert tr;

        Test.startTest();
            con.Household__c = hshold.Id;
            update con;

            Batch_ProfileAutoUpdate batchClass = new Batch_ProfileAutoUpdate(); 
            Database.ExecuteBatch(batchClass, 1);

            List<Test_Respondent__c> trList = new List<Test_Respondent__c>();
            trList.add(tr);
            batchClass.execute(null, trList);

            System.schedule('my batch job', '0 0 0 1 1 ?', new Batch_ProfileAutoUpdate() );
      	Test.stopTest();

    }

    static String buildTestScreener() {
        //Looks at the profile data we have saved in custom metadata and builds example JSON
        String returnVal = '[';
        for(Profile_Update__mdt pu : [SELECT Survey_Key__c, Survey_Value__c, Survey_Value_Direct_Copy__c, Salesforce_Field_Type__c FROM Profile_Update__mdt]) {
            if(pu.Survey_Value_Direct_Copy__c == true) {
                if(pu.Salesforce_Field_Type__c == 'Boolean') {
                    returnVal += '{"value":"1","key":"' + pu.Survey_Key__c + '"},';
                } else if(pu.Salesforce_Field_Type__c == 'Date') {
                    returnVal += '{"value":"01/01/1970","key":"' + pu.Survey_Key__c + '"},';
                } else if(pu.Salesforce_Field_Type__c == 'Number') {
                    returnVal += '{"value":"5","key":"' + pu.Survey_Key__c + '"},';
                } else {
                    returnVal += '{"value":"something","key":"' + pu.Survey_Key__c + '"},';
                }
            } else {
                returnVal += '{"value":"' + pu.Survey_Value__c + '","key":"' + pu.Survey_Key__c + '"},';
            }
        }
        returnVal += '{"value":"nothing","key":"nothing"}]';

        return returnVal;
    }
}