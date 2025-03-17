public class RestApi_Salesforce {
	public static String Salesforce_CreateFolder(String folderName) {
		Http httpProtocol = null;
		HttpRequest request = null;
		HttpResponse response = null;
		String folderdev = folderName.replaceAll(' ', '_');
		String SessionId = UserInfo.getSessionId();
		String sfdcInstance = System.URL.getSalesforceBaseUrl().getHost();
		String endpoint = 'https://' + sfdcInstance + '/services/data/v34.0/sobjects/Folder/';
		String rBody = '{"AccessType":"Public","Name":"'+ folderName +'","AccessType":"Public","Type":"Report","DeveloperName":"'+ folderdev +'"}';
		String strTestJSONResponse;

		httpProtocol = new Http();
		request = new HttpRequest();
		request.setHeader('Authorization', 'OAuth ' + sessionId);
		request.setEndpoint(endpoint);
		request.setMethod('POST');
		request.setHeader('Content-Type', 'application/json');
		request.setBody(rBody);

		try{
			if(Test.isRunningTest()){
				HttpResponse res = new HttpResponse();
				res.setStatus('OK');
				res.setStatusCode(200);
				strTestJSONResponse = '{"id":"00lR0000000v8ahIAA","success":true,"errors":[]}';
				res.setBody(strTestJSONResponse);
				response = res;
			}
			else{
				response = httpProtocol.send(request);
			}
		}
		catch (Exception ex){
			system.debug(LoggingLevel.ERROR, '\n\n***Error on http request:\n' + ex);
		}
		
		return response.getBody();
	}
	public static String Salesforce_CreateReport(String reportId, String folderId, String filters) {
		Http httpProtocol = null;
		HttpRequest request = null;
		HttpResponse response = null;
		String SessionId = UserInfo.getSessionId();
		String sfdcInstance = System.URL.getSalesforceBaseUrl().getHost();
		String endpoint = 'https://' + sfdcInstance + '/services/data/v34.0/analytics/reports?cloneId=' + reportId;
		String rBody = '{ "reportMetadata" : {"folderId":"'+ folderId +'",'+ filters +'}}';
		String strTestJSONResponse;

		System.debug('rBody: ' + rBody);
		httpProtocol = new Http();
		request = new HttpRequest();
		request.setHeader('Authorization', 'OAuth ' + sessionId);
		request.setEndpoint(endpoint);
		request.setMethod('POST');
		request.setHeader('Content-Type', 'application/json');
		request.setBody(rBody);


		try{
			if(Test.isRunningTest()){
				HttpResponse res = new HttpResponse();
				res.setStatus('OK');
				res.setStatusCode(200);
				strTestJSONResponse = '{"reportMetadata":{"aggregates":["RowCount"],"currency":null,"detailColumns":["OPPORTUNITY_NAME","AMOUNT","EXP_AMOUNT","CLOSE_DATE","NEXT_STEP","STAGE_NAME","PROBABILITY","FISCAL_QUARTER","AGE","CREATED_DATE","FULL_NAME","ACCOUNT_NAME"],"developerName":"Test_Report16","division":null,"folderId":"00lR0000000v7nQIAQ","groupingsAcross":[],"groupingsDown":[],"hasDetailRows":true,"hasRecordCount":true,"historicalSnapshotDates":[],"id":"00OR0000000pzqaMAA","name":"Test Report","reportBooleanFilter":null,"reportFilters":[{"column":"AGE","isRunPageEditable":false,"operator":"greaterThan","value":"100"}],"reportFormat":"TABULAR","reportType":{"label":"Opportunities","type":"Opportunity"},"scope":"organization","sortBy":[],"standardDateFilter":{"column":"CLOSE_DATE","durationValue":"THIS_FISCAL_QUARTER","endDate":"2016-09-30","startDate":"2016-07-01"},"standardFilters":[{"name":"open","value":"all"},{"name":"probability","value":">0"}]}}';
				res.setBody(strTestJSONResponse);
				response = res;
			}
			else{
				response = httpProtocol.send(request);
			}
		}
		catch (Exception ex){
			system.debug(LoggingLevel.ERROR, '\n\n***Error on http request:\n' + ex);
		}
		return response.getBody();
	}
	public static String Salesforce_GetReport(String reportId){
		Http httpProtocol = null;
		HttpRequest request = null;
		HttpResponse response = null;
		String SessionId = UserInfo.getSessionId();
		String sfdcInstance = System.URL.getSalesforceBaseUrl().getHost();
		String endpoint = 'https://' + sfdcInstance + '/services/data/v34.0/analytics/reports/'+ reportId +'/describe';
		String strTestJSONResponse;

		httpProtocol = new Http();
		request = new HttpRequest();
		request.setHeader('Authorization', 'OAuth ' + sessionId);
		request.setEndpoint(endpoint);
		request.setMethod('GET');

		try{
			if(Test.isRunningTest()){
				HttpResponse res = new HttpResponse();
				res.setStatus('OK');
				res.setStatusCode(200);
				strTestJSONResponse = '{"reportMetadata":{"aggregates":["RowCount"],"currency":null,"detailColumns":["OPPORTUNITY_NAME","AMOUNT","EXP_AMOUNT","CLOSE_DATE","NEXT_STEP","STAGE_NAME","PROBABILITY","FISCAL_QUARTER","AGE","CREATED_DATE","FULL_NAME","ACCOUNT_NAME"],"developerName":"Test_Report16","division":null,"folderId":"00lR0000000v7nQIAQ","groupingsAcross":[],"groupingsDown":[],"hasDetailRows":true,"hasRecordCount":true,"historicalSnapshotDates":[],"id":"00OR0000000pzqaMAA","name":"Test Report","reportBooleanFilter":null,"reportFilters":[{"column":"AGE","isRunPageEditable":false,"operator":"greaterThan","value":"100"}],"reportFormat":"TABULAR","reportType":{"label":"Opportunities","type":"Opportunity"},"scope":"organization","sortBy":[],"standardDateFilter":{"column":"CLOSE_DATE","durationValue":"THIS_FISCAL_QUARTER","endDate":"2016-09-30","startDate":"2016-07-01"},"standardFilters":[{"name":"open","value":"all"},{"name":"probability","value":">0"}]}}';
				res.setBody(strTestJSONResponse);
				response = res;
			}
			else{
				response = httpProtocol.send(request);
			}
		}
		catch (Exception ex){
			system.debug(LoggingLevel.ERROR, '\n\n***Error on http request:\n' + ex);
		}
		return response.getBody();

	} 
}