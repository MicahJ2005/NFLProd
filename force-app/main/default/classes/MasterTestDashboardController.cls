public with sharing class MasterTestDashboardController {
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
*   20140718  	Andy Boettcher DCS		Created
*   =============================================================================
*/
    public User objUser {get;set;}

	///////////////////////////
	// Constructors
	///////////////////////////
	public MasterTestDashboardController() { 
    	// Get User Brand
        objUser = [SELECT Id, Brand__c FROM User WHERE Id = :UserInfo.getUserId()];
    }	
    
	///////////////////////////
	// GET/SET
	///////////////////////////
	public List<SelectOption> lstLocations {
		get {
			lstLocations = new List<SelectOption>();
			for(String strObj : UtilityMethods.getValuesForPicklist('Task_Queue__c', 'Location_of_Test__c')) {
				lstLocations.add(new SelectOption(strObj, strObj));
			}
			return lstLocations;
		}
		set;
	}
	
	public List<SelectOption> lstServiceLines {
		get {
			lstServiceLines = new List<SelectOption>();
			for(String strObj : UtilityMethods.getValuesForPicklist('Task_Queue__c', 'CFS_Service_Line__c')) {
				lstServiceLines.add(new SelectOption(strObj, strObj));
			}
			return lstServiceLines;
		}
		set;
	}
	
	///////////////////////////
	// Action Methods
	///////////////////////////
	@RemoteAction
	public static List<hClsSource> lstCalendarEvents(String strStart, String strEnd, String strServiceLine, String strTestLocations) {

		List<hClsSource> lstReturn = new List<hClsSource>();
		Date dtePast = Date.valueOf(strStart);
		Date dteFuture = Date.valueOf(strEnd);
		//Date dtePast = System.Today().addMonths(-3);
		//Date dteFuture = System.Today().addMonths(3);
		
		strServiceLine = strServiceLine.replace('[', '');
		strServiceLine = strServiceLine.replace(']', '');
		strTestLocations = strTestLocations.replace('[', '');
		strTestLocations = strTestLocations.replace(']', '');

		List<String> lstSelectedServiceLines = new List<String>();
		List<String> lstSelectedLocations = new List<String>();

		for(String strLine : strServiceLine.split(',')) {
			lstSelectedServiceLines.add(strLine.trim());
		}

		for(String strLine : strTestLocations.split(',')) {
			lstSelectedLocations.add(strLine.trim());
		}

		// Get Preferences
		UserPreference__c uPref = UserPreference__c.getInstance(UserInfo.getUserId());
		Set<Id> setHiddenIds = new Set<Id>();
		if(uPref.Hidden_Calendars__c != NULL && uPref.Hidden_Calendars__c != '') {
			for(String str : uPref.Hidden_Calendars__c.split(',')) {
				setHiddenIds.add(str);
			}
		}
        
        // Get User Brand
        // User objUser = [SELECT Id, Brand__c FROM User WHERE Id = :UserInfo.getUserId()];

		// Get Sources
		List<CalendarSources__c> lstCSSources = [SELECT Id, Name, IsActive__c, Background_Color__c, End_Field__c, 
													Legend_Order__c, Object__c, SOQL_Select__c, SOQL_Where__c, 
													Start_Field__c, Subject_Field__c, Text_Color__c 
													FROM CalendarSources__c
													WHERE IsActive__c = true
													ORDER BY Legend_Order__c ASC];

		for(CalendarSources__c cs : lstCSSources) {

			System.Debug('dtePast = ' + dtePast);
			System.Debug('dteFuture = ' + dteFuture);
			System.Debug('Service Lines = ' + JSON.serialize(lstSelectedServiceLines));
			System.Debug('Locations = ' + JSON.serialize(lstSelectedLocations));

			List<hClsEvent> lstEvents = new List<hClsEvent>();
			hClsSource clsSource = new hClsSource();
			clsSource.strName = cs.Name;
			clsSource.strSourceId = cs.Id;
			clsSource.strChecked = '';

			if(!setHiddenIds.contains(cs.Id)) {

				clsSource.strChecked = 'checked';

				Map<String, String> mapLabels = UtilityMethods.fieldLabelsForNames(cs.Object__c);

				String strQuery = '';
				if(cs.Object__c == 'Task_Queue__c') {
					strQuery += 'SELECT Actual_Calendar_Dates_Start__c, Actual_Calendar_Dates_End__c, ';
					strQuery += 'Actual_Calendar_Times_Start__c, Actual_Calendar_Times_End__c, All_Day_Event__c, ';
					strQuery += cs.SOQL_Select__c + ' FROM ' + cs.Object__c;
					strQuery+= ' WHERE ' + cs.Start_Field__c + ' > :dtePast ';
				} else {
					strQuery += 'SELECT ' + cs.SOQL_Select__c + ' FROM ' + cs.Object__c;
					strQuery+= ' WHERE ' + cs.Start_Field__c + ' > :dtePast ';
				}

				if(cs.End_Field__c != null) {
					strQuery+= ' AND ' + cs.End_Field__c + ' < :dteFuture ';
				}
								
				// TODO:  Talk to Matt about parsing this stuff out for complicated WHERE statements
				if(cs.SOQL_Where__c != null) {
					strQuery+= ' AND ' + cs.SOQL_Where__c;
				}

				// TODO:  Make this dynamic - only accounts for Task Queues
				if(!Test.isRunningTest()) {
					if(!lstSelectedServiceLines.isEmpty()) {
						strQuery+= ' AND CFS_Service_Line__c IN :lstSelectedServiceLines ';
					}

					if(!lstSelectedLocations.isEmpty()) {
						strQuery+= ' AND Location_of_Test__c IN :lstSelectedLocations ';
					}
				}

				System.Debug('CALENDAR QUERY HERE');
				System.Debug(strQuery);

				for(sObject so : Database.Query(strQuery)) {

					Map<String,Object> fieldsMap = (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(so));
					System.Debug(fieldsMap);

					Date startDate = (Date)so.get(cs.Start_Field__c);
					Date endDate = (Date)so.get(cs.End_Field__c);

						//if this isn't a task queue - it's automatically an all day event
					Time startTime = Time.newInstance(0,0,0,0);
					Time endTime = Time.newInstance(0,0,0,0);
					Boolean allDay = true;

					if(cs.Object__c == 'Task_Queue__c') {
						startTime = (Time)so.get('Actual_Calendar_Times_Start__c');
						endTime = (Time)so.get('Actual_Calendar_Times_End__c');
						allDay = (Boolean)so.get('All_Day_Event__c');
						if(allDay == false && endDate > startDate) {
							//this is a multi-day test - with times.  
							/** Example: 
							 * Start Date: Mon; Start Time: 2pm
							 * End Date: Wed; End Time: 4pm
							 * 
							 * That means - we want 3 separate things on the calendar - 
							 * Mon 2-4; Tue 2-4 and Wed 2-4  
							 * NOT Monday 2pm through Wednesday 4pm
							 */
						}
					} 
					if(startTime == null && endTime == null) {
						allDay = true;
					}

					if(startTime == null) {
						startTime = Time.newInstance(0,0,0,0);
					}
					if(endTime == null) {
						endTime = Time.newInstance(0,0,0,0);
					}

					//clsE.dtmStart = (Datetime)so.get(cs.Start_Field__c);
					//clsE.dtmEnd = (Datetime)so.get(cs.End_Field__c);
					
					//if this is an all day event - we don't need to do the fancy split
					if(allDay) {
						hClsEvent clsE = new hClsEvent();

						//clsE.dtmStart = DateTime.newInstanceGmt(startDate, startTime);
						//clsE.dtmEnd = DateTime.newInstanceGmt(endDate, endTime);

						clsE.dtmStart = DateTime.newInstanceGmt(startDate, startTime);
						clsE.dtmEnd = DateTime.newInstanceGmt(endDate, endTime);

						clsE.strId = (String)so.get('Id');
						clsE.strTitle = (String)so.get(cs.Subject_Field__c);
						clsE.boolAllDay = allDay;

						//clsSource.strBGCOLOR = cs.Background_Color__c;
						//clsSource.strCOLOR = cs.Text_Color__c;

						List<hClsEventDetail> lstDetail = new List<hClsEventDetail>();
						for(String str : cs.SOQL_Select__c.split(',')) {
							String strName = str.trim();
							if(mapLabels.containsKey(strName.toLowerCase()) && strName.toLowerCase() != 'id') {
								lstDetail.add(
									new hClsEventDetail(mapLabels.get(strName.toLowerCase()), so.get(strName))
								);
							}
						}

						clsE.lstData = lstDetail;
						lstEvents.add(clsE);
					} else {
						Date tmpDate = startDate;
						while(tmpDate <= endDate) {
							hClsEvent clsE = new hClsEvent();

							//clsE.dtmStart = DateTime.newInstanceGmt(startDate, startTime);
							//clsE.dtmEnd = DateTime.newInstanceGmt(endDate, endTime);

							clsE.dtmStart = DateTime.newInstanceGmt(tmpDate, startTime);
							clsE.dtmEnd = DateTime.newInstanceGmt(tmpDate, endTime);

							clsE.strId = (String)so.get('Id');
							clsE.strTitle = (String)so.get(cs.Subject_Field__c);
							clsE.boolAllDay = allDay;

							//clsSource.strBGCOLOR = cs.Background_Color__c;
							//clsSource.strCOLOR = cs.Text_Color__c;

							List<hClsEventDetail> lstDetail = new List<hClsEventDetail>();
							for(String str : cs.SOQL_Select__c.split(',')) {
								String strName = str.trim();
								if(mapLabels.containsKey(strName.toLowerCase()) && strName.toLowerCase() != 'id') {
									lstDetail.add(
										new hClsEventDetail(mapLabels.get(strName.toLowerCase()), so.get(strName))
									);
								}
							}

							clsE.lstData = lstDetail;
							lstEvents.add(clsE);

							tmpDate = tmpDate.addDays(1);
							
						} //END while loop

					} //END if/else

					clsSource.strBGCOLOR = cs.Background_Color__c;
					clsSource.strCOLOR = cs.Text_Color__c;

				}

			}

			// Add Event List to Source Wrapper
			clsSource.lstEvents = lstEvents;
			lstReturn.add(clsSource);
		}

		return lstReturn;

	}

	@RemoteAction
	public static void toggleVisibility(Id strId, Boolean bolVisible) {

		Set<Id> setHiddenIds = new Set<Id>();
		String strValue = '';

		// Step 1:  Pull all existing
		UserPreference__c uPref = UserPreference__c.getInstance(UserInfo.getUserId());
		if(uPref.Hidden_Calendars__c != NULL && uPref.Hidden_Calendars__c != '') {
			for(String str : uPref.Hidden_Calendars__c.split(',')) {
				setHiddenIds.add(str);
			}
		}

		// Step 2A:  Add to hidden list
		if(!bolVisible) {
			setHiddenIds.add(strId);	
		}

		// Step 2B:  Remove from hidden list
		if(bolVisible) {
			setHiddenIds.remove(strId);	
		}

		// Step 3:  Output to String
		for(Id idVal : setHiddenIds) {
			strValue+=(strValue==''?'':',')+idVal;
		}

		// Step 4:  Save
		uPref.Hidden_Calendars__c = strValue;
		upsert uPref;

	}
	
	///////////////////////////
	// Inner / Helper Classes
	///////////////////////////
	public class hClsSource {

		public String strSourceId {get;set;}
		public String strName {get;set;}
		public String strBGCOLOR {get;set;}
		public String strCOLOR {get;set;}
		public String strChecked {get;set;}
		public List<hClsEvent> lstEvents {get;set;}
	}

	public class hClsEvent {

		public Datetime dtmStart {get;set;}
		public Datetime dtmEnd {get;set;}
		public String strId {get;set;}
		public String strTitle {get;set;}
		public Boolean boolAllDay { get; set; }
		//public String strBGCOLOR {get;set;}
		//public String strCOLOR {get;set;}
		public List<hClsEventDetail> lstData {get;set;}

		public hClsEvent() { }

	}

	public class hClsEventDetail {

		public String strField {get;set;}
		public Object strData {get;set;}

		public hClsEventDetail(String passField, Object passData) {
			strField = passField;
			strData = passData;
		}
	}
}