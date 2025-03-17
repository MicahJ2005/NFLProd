public with sharing class TRBeaconQuotaDisplayController {
/**
*   {Purpose}  �  Parse and display the Beacon Results stored in the "TR.Screener_Results__c" field
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   20150318  	Andy Boettcher DCS		Created
*   =============================================================================
*/
	private Id idRecord;


	///////////////////////////
	// Constructors
	///////////////////////////
	public TRBeaconQuotaDisplayController(ApexPages.StandardController scMain) {
		idRecord = scMain.getId();
	}
	
	
	///////////////////////////
	// GET / SET
	///////////////////////////
	public List<hClsQuota> lstQuotas {

		get {
			// GET QUOTA INFORMATION
	        List<hClsQuota> lstTemp = new List<hClsQuota>();

	        // Spin through all Respondents
	        for(Test_Respondent__c tr : [SELECT Screener_Results__c FROM Test_Respondent__c WHERE Id = :idRecord]) {

	            // Put all in list first
	            List<hClsQuota> lstAll = new List<hClsQuota>();
	            if(tr.Screener_Results__c != null) {
	                lstAll = (List<hClsQuota>)JSON.deserialize(tr.Screener_Results__c, List<hClsQuota>.class);
	                for(hClsQuota clsQ : lstAll) {
	                	System.Debug('Checking ' + clsQ.key + ' - ' + clsQ.key.indexOf('conditions') + '|' + clsQ.key.indexOf('conditionsIGNORE'));
	                    if(clsQ.key.indexOf('conditions') >= 0 && clsQ.key.indexOf('conditionsIGNORE') <= 0) {
	                        lstTemp.add(clsQ);
	                    }
	                }
	            } else {
	                hClsQuota clsQ = new hClsQuota();
	                clsQ.key = 'No Quota Information';
	                clsQ.value = 'No Quota Information';
	                lstTemp.add(clsQ);
	            }
	            	            
	        }

	        return lstTemp;
	    }
	}
	
	///////////////////////////
	// Inner / Helper Classes
	///////////////////////////
	public class hClsQuota {
        public String key {get;set;}
        public String value {get;set;}
    }
}