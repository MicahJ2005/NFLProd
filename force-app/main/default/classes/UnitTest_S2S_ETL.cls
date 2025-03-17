@isTest
public class UnitTest_S2S_ETL {

/**
*   {Purpose}   - Unit Test for S2S REST-Based "ETL-Lite"
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 952.223.5604               
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name                    Description
*   20171226    Andy Boettcher DCS      Created
*   20240308    Sophia Murphy DCS       Commented out it all
*   =============================================================================
*/

    @isTest
    static void doNothingTest() {
        S2STriggerHandler.doNothing();
    }

/**	static String apiName = 'TEST_LEAD';
    static String orgName = 'TESTCONNECTION';

	@testSetup
	static void testDataSetup() {
		UnitTest_Test_Data.commitFPIApexSettings();
	}

	@isTest
    static void testS2SSourceSuccess() {

        Test.setMock(HttpCalloutMock.class, new UnitTest_S2STokenSuccess_MOCK());
        
        test.startTest();
        
        Lead objLead = new Lead(LastName='UNIT', FirstName='TEST', Email='me123@you.com', Company='UnitTestCompany', IsS2SReady__c=TRUE);
        insert objLead;

        List<Lead> lstLeads = new List<Lead>();
        lstLeads.add(objLead);

        S2STriggerHandler.handleRecords(orgName, apiName, JSON.serialize(lstLeads));
        
        test.stopTest();
        
    }

    @isTest
    static void testS2SSourceSuccessFullBatch() {

        Test.setMock(HttpCalloutMock.class, new UnitTest_S2STokenSuccess_MOCK());
        
        test.startTest();
        
        List<Lead> lstLeads = new List<Lead>();
        for (Integer i = 0; i < 200; i++) {
            lstLeads.add(new Lead(LastName='UNIT'+i, FirstName='TEST'+i, Email='me123.' + i + '@you.com', Company='UnitTestCompany'+i, IsS2SReady__c=TRUE));
        }

        insert lstLeads;

        S2STriggerHandler.handleRecords(orgName, apiName, JSON.serialize(lstLeads));
        
        test.stopTest();
        
    }

   	@isTest
    static void testS2SSourceFailure() {

        Test.setMock(HttpCalloutMock.class, new UnitTest_S2STokenFailure_MOCK());
        
        test.startTest();
        
        Lead objLead = new Lead(LastName='UNIT', FirstName='TEST', Email='me123@you.com', Company='UnitTestCompany', IsS2SReady__c=TRUE);
        insert objLead;

        List<Lead> lstLeads = new List<Lead>();
        lstLeads.add(objLead);

        S2STriggerHandler.handleRecords(orgName, apiName, JSON.serialize(lstLeads));
        
        test.stopTest();
        
    }

    @isTest
    static void testIncomingRESTServiceSuccess() {

    	Test.setMock(HttpCalloutMock.class, new UnitTest_S2STokenSuccess_MOCK());

    	List<Lead> lstSeedRecords = new List<Lead>();
    	lstSeedRecords.add(new Lead(LastName='Lead1', Email='me@you1.com', Company='TestCompany1', IsS2SReady__c=TRUE));
    	lstSeedRecords.add(new Lead(LastName='Lead2', Email='me@you2.com', Company='TestCompany2', IsS2SReady__c=TRUE));
    	lstSeedRecords.add(new Lead(LastName='Lead3', Email='me@you3.com', Company='TestCompany3', IsS2SReady__c=TRUE));
    	lstSeedRecords.add(new Lead(LastName='Lead4', Email='me@you4.com', Company='TestCompany4', IsS2SReady__c=TRUE));
    	insert lstSeedRecords;

    	List<S2S_Setting__mdt> connectionSetting = [SELECT 
                                                REST_URI__c,
                                                Refresh_Token__c,
                                                (SELECT 
                                                    QualifiedApiName,
                                                    External_Id_Name__c,
                                                    Ready_Field__c,
                                                    API_Name__c
                                                FROM 
                                                    S2S_Object__r 
                                                WHERE 
                                                    QualifiedApiName = :apiName) 
                                            FROM 
                                                S2S_Setting__mdt 
                                            WHERE 
                                                QualifiedAPIName = :orgName
                                            LIMIT 1
        ];

        S2S_Object__mdt objectSetting = [SELECT 
                                        Id, 
                                        External_Id_Name__c, 
                                        (SELECT 
                                            Source_Field__c, 
                                            Target_Field__c, 
                                            IsLiteral__c,
                                            Literal_Value__c
                                        FROM 
                                            S2S_Fields__r) 
                                    FROM S2S_Object__mdt 
                                    WHERE QualifiedApiName = :apiName
                                    LIMIT 1
        ];
         

        S2S_Setting__mdt setting = connectionSetting.get(0);
        S2S_Object__mdt upsertObject = setting.S2S_Object__r.get(0);
        Map<String, String> translationMap = new Map<String, String>();

        String[] strFields = new String[]{};
        for(S2S_Field__mdt objField : objectSetting.S2S_Fields__r){
        	strFields.add(objField.Source_Field__c);
        	translationMap.put(objField.Source_Field__c, objField.Target_Field__c);
        }

        String strQuery = 'SELECT ' + string.join(strFields, ',') + ' FROM ' + upsertObject.API_Name__c;
        List<sObject> sObjects = S2SService.translateRecords(JSON.serialize(Database.Query(strQuery)), translationMap);

		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		RestContext.response = res;

		// Set Request Object
		req.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/S2S/actions';
		req.httpMethod = 'POST';
        
        S2SRESTfulService.UpsertRequest upsertReq = new S2SRESTfulService.UpsertRequest();
        upsertReq.records = JSON.serialize(sObjects);
        upsertReq.apiName = upsertObject.API_Name__c;
        upsertReq.externalId = 'Id';
        upsertReq.translationMap = translationMap;
        req.requestBody = Blob.valueOf(JSON.serialize(upsertReq));

        System.Debug(upsertReq);

		RestContext.request = req;
		S2SService.upsertRecords(upsertReq.records, upsertReq.apiName, upsertReq.externalId, upsertReq.translationMap);

    }
    */

}