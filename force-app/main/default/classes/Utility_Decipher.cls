public with sharing class Utility_Decipher {
/**
*   {Purpose}  �  Queries Decipher / Beacon to return screener results for people who ended
*					early or Decipher was just too slow processing to deal with it.
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20141103  	Andy Boettcher DCS		Created
*	20210708	Sophia Murphy DC		Changed decipher password
*   =============================================================================
*/
	private static final String DECIPHER_REPORT_URL = 'https://selfserve.decipherinc.com/api/data/tab';
	private static final String DECIPHER_USERNAME = 'morgan.catlin@valtira.net';
	//private static final String DECIPHER_PASSWORD = 'dY4hxcH2Yf';
	//private static final String DECIPHER_PASSWORD = '92-wVWG6-b@fDprmBZve';
	private static final String DECIPHER_PASSWORD = 'Q9yba*MWfDNioBFj-';

	///////////////////////////
	// Constructors
	///////////////////////////
	//public Utility_Decipher() { }	
	
	///////////////////////////
	// Action Methods
	///////////////////////////
	public static void downloadIncompleteResults(List<hClsTargetTR> lstTargetTR) {

		/**********************************************
		*
		* We are processing these through the WS_WebProcessor REST service, 
		* which is built for single-usage only from FPITesters.  Because of that, we are 
		* going to limit this to 15 TRs per invocation.  (4 SOQL queries per record)
		*
		***********************************************/
		Integer iLimit = 15; Integer iRecord = 1;
		List<WS_WebProcessor.wsRequest> lstRequests = new List<WS_WebProcessor.wsRequest>();

		for(hClsTargetTR clsTarget : lstTargetTR) {
			
			//// Protect Limits!
			if(iRecord == iLimit || 
				Limits.getCallouts() >= Limits.getLimitCallouts() ||
				Limits.getQueries() >= Limits.getLimitQueries()) {
				System.Debug('LIMIT REACHED - downloadIncompleteResults');
				System.Debug(iRecord + ' = ' + iLimit);
				System.Debug(Limits.getCallouts() + ' >= ' + Limits.getLimitCallouts());
				System.Debug(Limits.getQueries() + ' >= ' + Limits.getLimitQueries());
				return;
			}

			// Query Decipher for Screener Results
			HTTPRequest decipherRequest = new HttpRequest();

			// ADDED 201506016 AAB - MAIN AND PAIRS SURVEY URL DETERMINATION
			// Determine which Survey URL to use
			String strSurvey = clsTarget.mt.Screener_Link__c;

			if(clsTarget.mt.Pairs_Test__c && clsTarget.tr.Respondent__r.Age__c < 18 && clsTarget.mt.Pairs_Screener_Link__c != null) {
				strSurvey = clsTarget.mt.Pairs_Screener_Link__c;
				System.Debug('MINOR FOUND IN PAIRS TEST, CHANGING SURVEY LINK TO PAIRED');
			}
			System.Debug('SWEEPING ' + clsTarget.tr.Id + ' WITH SURVEY LINK ' + strSurvey);
			strSurvey = strSurvey.substring(strSurvey.indexOf('survey/') + 7); //  selfserve/1f45/140507

			// Assemble endpoint URL
			String endpointURL = DECIPHER_REPORT_URL + '?survey=' + strSurvey + '&var:contactid=' + clsTarget.tr.Respondent__c;
			decipherRequest.setEndpoint(endpointURL);

			// Assemble Authentication
			Blob headerValue = Blob.valueOf(DECIPHER_USERNAME + ':' + DECIPHER_PASSWORD);
			String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);

			// Assemble outbound HTTP Request
			decipherRequest.setHeader('Authorization', authorizationHeader);
			decipherRequest.setMethod('GET');

			// Submit HTTP Request to Decipher
			Http decipherHTTP = new Http();
			HttpResponse decipherResponse;

			if(test.isRunningTest()) {
				decipherResponse = new HttpResponse();
				decipherResponse.setStatusCode(200);
				decipherResponse.setBody('field1\tfield2\tfield3\t\nvalue1\tvalue2\tvalue3');
			} else {
				decipherResponse = decipherHTTP.send(decipherRequest);
			}
			
			if(decipherResponse.getStatusCode() != 200) {
				System.Debug('DECIPHER CALLOUT FAILED - ' + decipherResponse.getBody());
				return;
			}

			// Parse Response Body
			//System.Debug(decipherResponse.getBody());
			String[] beaconResults = decipherResponse.getBody().split('\n');
			List<WS_WebProcessor.jsonQuestion> lstResults = new List<WS_WebProcessor.jsonQuestion>();

			if(beaconResults.size() >= 2) {
				System.Debug('PROCESSING SCREENER RESULTS');
				String[] headerLine = beaconResults[0].split('\t');
				String[] recordLine = beaconResults[1].split('\t');

				System.Debug(headerLine.size() + ' ' + recordLine.size());

				if(headerLine.size() > recordLine.size()) {
					System.Debug('FOUND BEACON DATA ERROR - ATTEMPTING TO COMPENSATION FOR MISSING DATA DELIMITERS!');
					System.Debug('CONTACTID = ' + clsTarget.tr.Respondent__c);
					System.Debug('SURVEY = ' + strSurvey);
					Integer iGap = headerLine.size() - recordLine.size();
					for(Integer i = 0; i < iGap; i++) {
						recordLine.add('');
					}

				}

				for(Integer i = 0; i < headerLine.size()-1; i++) {
					//if(i <= recordLine.size()-1) {
						lstResults.add(new WS_WebProcessor.jsonQuestion(headerLine[i], recordLine[i]));
					//}
				}
			}

			// Assemble REST Request
			WS_WebProcessor.wsRequest wsRequest = new WS_WebProcessor.wsRequest();
			wsRequest.trRespondent = clsTarget.tr;
			wsRequest.mtTest = clsTarget.mt;
			wsRequest.actionName = 'screenerAddResults';
			wsRequest.jsonBulkData = lstResults;
			lstRequests.add(wsRequest);
		}

		// All Callouts are done, process DML work!
		for(WS_WebProcessor.wsRequest wsRequest : lstRequests) {

			WS_WebProcessor.wsResponse wsResponse = new WS_WebProcessor.wsResponse();
			RestRequest req = new RestRequest();
			RestResponse res = new RestResponse();
			RestContext.response = res;

			// Set Request Object
			req.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/actions';
			req.httpMethod = 'POST';

			req.requestBody = Blob.valueOf(JSON.serialize(wsRequest));
			RestContext.request = req;
			WS_WebProcessor.actionRouter();
			//wsResponse = (WS_WebProcessor.wsResponse)JSON.deserializeStrict(RestContext.response.responseBody.ToString(), WS_WebProcessor.wsResponse.class);
		}
	}
	
	///////////////////////////
	// Inner / Helper Classes
	///////////////////////////
	public class hClsTargetTR {
		public Test_Respondent__c tr {get;set;}
		public Master_Test__c mt {get;set;}
		public hClsTargetTR(Test_Respondent__c passTR, Master_Test__c passMT) {
			tr = passTR;
			mt = passMT;
		}
	}
}