public with sharing class TestExcludedProjectsController {
/**
*   {Purpose}  �  TODO:  Provide Purpose
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date    	Name             		Description
*   YYYYMMDD  	FN LN DCS				Created
*   =============================================================================
*/
	private Master_Test__c tmRecord;
	public List<hClsAvailable> lstAvailableProjects {get;set;}
	public List<hClsAvailable> lstExcludedProjects {get;set;}
	private Set<String> setProjects = new Set<String>();
	public String strSearch {get;set;}

	///////////////////////////
	// Constructors
	///////////////////////////
	public TestExcludedProjectsController(ApexPages.StandardController scController) {

		tmRecord = [SELECT Id, Name, Excluded_Projects__c FROM Master_Test__c WHERE Id = :scController.getId()];
		System.Debug(tmRecord);

		try {
			if(tmRecord.Excluded_Projects__c.length() > 0) {
				List<String> lstProjects = (List<String>)JSON.deserialize(tmRecord.Excluded_Projects__c, List<String>.class);
				for(String str : lstProjects) { setProjects.add(str); }	
			}
		} catch(Exception ex) {
			System.Debug(ex);
		}

		strSearch = '';

		fillExcludedProjectsList();
		lstAvailableProjects = new List<hClsAvailable>(); 
	}
		
	///////////////////////////
	// Action Methods
	///////////////////////////
	public void fillAvailableProjectList() {
		lstAvailableProjects = new List<hClsAvailable>(); 

		String strQuery = 'SELECT Id,Project_Number__c, Public_Test_Description__c, First_Session_Start__c, Last_Session_Start__c ';
		strQuery+=' FROM Master_Test__c ';
		strQuery+=' WHERE Project_Number__c != null AND (Project_Number__c LIKE \'%' + strSearch + '%\' OR Public_Test_Description__c LIKE \'%' + strSearch + '%\') ';
		strQuery+=' ORDER BY Project_Number__c ASC';

		for(Master_Test__c mt : Database.query(strQuery)) {
			lstAvailableProjects.add(new hClsAvailable(mt,false));
		}
	}

	public void fillExcludedProjectsList() {
		lstExcludedProjects = new List<hClsAvailable>(); 
		for(Master_Test__c mt : [SELECT Id, Project_Number__c, Public_Test_Description__c, First_Session_Start__c, Last_Session_Start__c
									FROM Master_Test__c WHERE Project_Number__c IN :setProjects]) {
			lstExcludedProjects.add(new hClsAvailable(mt,false));
		}
	}

	public PageReference saveExcludedProjects() {
		
		Set<String> setProjectNumbers = new Set<String>();

		for(hClsAvailable hcls : lstExcludedProjects) {
			if(!hcls.bolChecked) { setProjectNumbers.add(hcls.mtProject.Project_Number__c); }
		}
		
		for(hClsAvailable hcls : lstAvailableProjects) {
			if(hcls.bolChecked) { setProjectNumbers.add(hcls.mtProject.Project_Number__c); }
		}

		tmRecord.Excluded_Projects__c = JSON.serialize(setProjectNumbers);
		update tmRecord;

		PageReference prRef = new PageReference('/'+tmRecord.Id);
		prRef.setRedirect(true);
		return prRef;

	}

	///////////////////////////
	// Inner Classes
	///////////////////////////
	public class hClsAvailable {
		public Boolean bolChecked {get;set;}
		//public ATC__Hlist__c atcListItem {get;set;}
		public Master_Test__c mtProject {get;set;}

		public hClsAvailable(Master_Test__c passListItem, Boolean passChecked) {
			mtProject = passListItem;
			bolChecked = passChecked;
		}
	}

}