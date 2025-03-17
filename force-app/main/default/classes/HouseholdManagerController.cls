public with sharing class HouseholdManagerController {

/**
*   {Purpose}  �  Controller for VF HouseholdManager page
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20131212  	Andy Boettcher (DCS)   	Created
*	20170510	Jeff Johnson (FPI)		updated lin 67 to add in the SOQL query Age__c, PID__C, Email
*   =============================================================================
*/

	public Id idRecord {get;set;}
	public String strRespondentId {get;set;}
	public Contact conSearch {get;set;}
	public Contact conNew {get;set;}
	private ApexPages.standardController scBackPage;
	public List<Household_Contact__c> lstMembers {get;set;}

	///////////////////////////////////
	// Constructors
	///////////////////////////////////	
	public HouseholdManagerController(ApexPages.standardController scMain) {
		idRecord = scMain.getId();
		scBackPage = scMain;
		conSearch = new Contact();
		conSearch.lastname = '';
		conNew = new Contact();
		refreshMemberList();
	}
	
	///////////////////////////////////
	// GET / SET
	///////////////////////////////////	
	public List<Contact> getLstContacts() {
		
		List<Contact> lstTemp = new List<Contact>();
		
		// Check for null criteria first
		if(conSearch.FirstName == null && conSearch.Title == null && conSearch.MailingCity == null && conSearch.MailingState == null) {
			UtilityMethods.LOG_MESSAGE('HouseholdManagerController.getLstContacts', 'EMPTY CRITERIA');
			return lstTemp;
		}
		
		// Get all ContactIds
		Set<Id> setContactIds = new Set<Id>();
		for(Household_Contact__c hcc : [SELECT Contact__c FROM Household_Contact__c WHERE Household__c = :idRecord]) {
			setContactIds.add(hcc.Contact__c);
		}
		
		UtilityMethods.LOG_MESSAGE('HouseholdManagerController.getLstContacts', 'Existing = ' + string.valueOf(setContactIds));
		
		// Get Contact Record Type
		Map<String, String> mapAppSettings = UtilityMethods.APP_SETTINGS();
		Set<Id> setRespondentIds = new Set<Id>();
		setRespondentIds.add(mapAppSettings.get('RT_ContactRespondentAdult'));
		setRespondentIds.add(mapAppSettings.get('RT_ContactRespondentChild'));
		
		// Construct SOQL
		Integer intCriteriaCount = 0;
		String strQuery = 'SELECT Id, Name, Birthdate, IsAdult__c, Status__c, Age__c, PID__C, Email FROM Contact WHERE ';
		strQuery += ' Id NOT IN :setContactIds AND RecordTypeId IN :setRespondentIds ';
		
		// First Name
		if(conSearch.FirstName != null) {
			strQuery += ' AND ';
			strQuery += ' FirstName LIKE \'%' + conSearch.FirstName + '%\' ';
		}
		
		// Last Name
		if(conSearch.Title != null) {
			strQuery += ' AND ';
			strQuery += ' LastName LIKE \'%' + conSearch.Title + '%\' ';
		}
		
		// Sorting and Limiting
		strQuery += ' ORDER BY LastName, FirstName LIMIT 100';
		
		UtilityMethods.LOG_MESSAGE('HouseholdManagerController.getLstContacts', 'SOQL = ' + strQuery);
		
		lstTemp = Database.Query(strQuery);
		
		UtilityMethods.LOG_MESSAGE('HouseholdManagerController.getLstContacts', 'Records = ' + lstTemp.size());
		
		conSearch = new Contact();
		conSearch.lastname = 'lastname';
		
		return lstTemp;
		
	}
	
	
	///////////////////////////////////
	// Action Methods
	///////////////////////////////////	
	public void refreshMemberList() {
		//lstMembers = [SELECT Id, Contact__c, Contact_Age__c, Guardian__c, Guardian__r.Name, Role__c, Relationship_to_HOH__c,
		//			Contact__r.Name, Contact__r.Lastname, Status__c 
		//		FROM Household_Contact__c
		//		WHERE Household__c = :idRecord ORDER BY Contact__r.LastName, Contact__r.FirstName];
		lstMembers = [SELECT Id, Contact__c, Contact_Age__c,
					Contact__r.Name, Contact__r.Lastname, Status__c, Contact__r.PID__c
				FROM Household_Contact__c
				WHERE Household__c = :idRecord ORDER BY Contact__r.LastName, Contact__r.FirstName];
	}

	public void saveMembers() {
		update lstMembers;
	}

	@RemoteAction
	public static String addRespondent(String passHouseholdId, String passContactId) {
		Household_Contact__c hhInsert = new Household_Contact__c(Household__c=passHouseholdId,Contact__c=passContactId);
		insert hhInsert;
		return 'success';
	}
	
	public void removeRespondent() {
		Household_Contact__c hhDelete = new Household_Contact__c(Id=strRespondentId);
		delete hhDelete;
		refreshMemberList();
	}
	
	public void saveNew() {

		WS_WebProcessor.wsRequest clsRequest = new WS_WebProcessor.wsRequest();
		WS_WebProcessor.wsResponse clsResponse = new WS_WebProcessor.wsResponse();
		clsRequest.actionName = 'respondentManage';
		clsRequest.conRespondent = conNew;
		RestRequest req = new RestRequest();
		RestResponse res = new RestResponse();
		RestContext.response = res;
		req.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/actions';
		req.httpMethod = 'POST';
		req.requestBody = Blob.valueOf(JSON.serialize(clsRequest));
		RestContext.request = req;
		WS_WebProcessor.actionRouter();
		clsResponse = (WS_WebProcessor.wsResponse)JSON.deserializeStrict(RestContext.response.responseBody.ToString(), WS_WebProcessor.wsResponse.class);

		//insert conNew;
		Household_Contact__c hhc = new Household_Contact__c(Household__c=idRecord,Contact__c=clsResponse.messageDetail);
		insert hhc;
		conNew = new Contact();
		refreshMemberList();	
	}

	public pageReference mergeHousehold() {
		PageReference prRef = new pageReference('/apex/HouseholdMerge?id=' + idRecord);
		prRef.setRedirect(true);
		return prRef;
	}
}