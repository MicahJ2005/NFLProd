/** 
Uses a standardSetController so it can be called from a list of Test Respondent records
Allows finance to check a number of TR records and reprint just those checks.

12.01.2020  Sophia Murphy (Demand Chain)
            Initial Creation
 */
public with sharing class CheckGenerator_TRListController {

    public ApexPages.StandardSetController setController;
    public Set<Id> trIds {get; set;}

    public CheckGenerator_TRListController(ApexPages.StandardSetController setCntrlr) {
        this.setController = setCntrlr;
        System.debug('setcontroller size: ' + setController.getSelected().size());      
        System.debug('setCntrlr size: ' + setCntrlr.getSelected().size());    
        
		//set the page size; else it will only show 20.
		//but only do this if the size is greater than 20.
		if(setCntrlr.getSelected().size() > 20) {
			setController.setPageSize(setController.getSelected().size());
		}
        
        trIds = new Set<Id>();
        for (Test_Respondent__c tr : (List<Test_Respondent__c>)setController.getSelected()){ 
            trIds.add(tr.Id);
        }
        system.debug('DC trIds ' + trIds);

    }

    public PageReference cancel() {
            return new ApexPages.Action('{!List}').invoke();
            //System.PageReference[/a09?fcf=00B24000004cfLK]
        
        
		//return null;
	}

    public PageReference runValtiraChecks() {
		return generatePDFChecks();
	}

    public PageReference generatePDFChecks() {

        system.debug('DC Entering generatePDFChecks');

		String strValtiraEndpoint = String.valueOf(FPI_AppSettings__c.getInstance('Valtira_Endpoint').Value__c);
		String strValtiraAPIKey = String.valueOf(FPI_AppSettings__c.getInstance('Valtira_APIKey').Value__c);

		UtilityMethods.hClsValtiraCheckGenerator clsCheckHandler = new UtilityMethods.hClsValtiraCheckGenerator();
		//clsCheckHandler.idMasterTest = idMasterTest;
		clsCheckHandler.lstRespondents = new List<Test_Respondent__c>();

		// Find only sessions that have been 'Generated'
		//Set<Id> setSessionIds = new Set<Id>();
		//for(Session__c ses : [SELECT Id FROM Session__c WHERE Related_Test__c = :clsCheckHandler.idMasterTest AND Check_Status__c = 'Generated']) {
		//	setSessionIds.add(ses.Id);
		//}

        //just testing
        //List<Test_Respondent__c> trList = new List<Test_Respondent__c>();
        //trList = setController.getSelected();

        system.debug('DC trIds ' + trIds);
		clsCheckHandler.lstRespondents = [SELECT Id, Check_Amount__c, Check_Memo__c, Check_Number__c,
											Check_Printed_Date__c, Respondent__c, Respondent__r.Name, Respondent__r.PID__c, 
											Master_Test__r.Project_Number__c, Master_Test__c, Donation_Amount_Per_Event__c,
											Session_Check_Amount__c, Organization__r.Name, Session_Id__c
											FROM Test_Respondent__c
                                            WHERE Id IN :trIds
                                            AND Check_Amount__c > 0
                                            AND Check_Number__c != null
                                            LIMIT 99];

		if(clsCheckHandler.lstRespondents.isEmpty()) { return null; }

		// ASSEMBLE CHECK DATA
		clsCheckHandler = CheckGeneratorController.generatePDFCheckData(clsCheckHandler);

		// ASSEMBLE THIS THING...
		CheckGeneratorController.valtiraEnvelope envelope = new CheckGeneratorController.valtiraEnvelope();
		envelope.forms = clsCheckHandler.formFields;
		
		Http objHttp = new Http();
		HttpRequest objReq = new HttpRequest();
		objReq.setTimeout(60000);
		objReq.setEndpoint(strValtiraEndpoint);
		objReq.setMethod('POST');
		objReq.setHeader('Content-Type', 'application/json');
		objReq.setHeader('x-api-key', strValtiraAPIKey);
		objReq.setBody(JSON.serialize(envelope));

		PageReference prReturn;

		try {
			HttpResponse objRes = objHttp.send(objReq);
			CheckGeneratorController.valtiraReturnEnvelope objResponse = (CheckGeneratorController.valtiraReturnEnvelope)JSON.deserialize(objRes.getBody(), CheckGeneratorController.valtiraReturnEnvelope.class);
			System.Debug(objResponse);

			if(objResponse.succeeded) {

				// Update the Session with Printed Status and Date
				//if(clsCheckHandler.mapUpdateSessions.size() > 0 && bolUpdateSession) { 
				//	update clsCheckHandler.mapUpdateSessions.values(); 
				//}

				prReturn = new PageReference(objResponse.location.url);
				prReturn.setRedirect(true);
				return prReturn;
			} else {
				return null;
			}
		} catch(Exception ex) {
			System.Debug(ex);
			return null;
		}

	}



}