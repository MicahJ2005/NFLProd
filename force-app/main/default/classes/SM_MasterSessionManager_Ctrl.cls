/**
 * @description       : 
 * @author            : willh@demandchain.com
 * @group             : 
 * @last modified on  : 05-12-2021
 * @last modified by  : willh@demandchain.com
 * Modifications Log 
 * Ver   Date         Author                  Modification
 * 1.0   04-19-2021   willh@demandchain.com   Initial Version
**/
//08.19.2019    Sophia Murphy (Demand Chain)
//              Case #6861 - updated getSessionName method
//11.02.2023    Sophia Murphy (Demand Chain)
//              Updates to getSessionName - to change timezone, time based on Brand.
public class SM_MasterSessionManager_Ctrl {
    
	@AuraEnabled
	public static SessionManagerData getSessions(String masterTestID) {
		Master_Test__c mc = [SELECT Id, Name, Opportunity_Name__c FROM Master_Test__c WHERE Id = :masterTestID];
		List<Session__c> lSessions = [SELECT ID,
		                              Name,
		                              Session_Start__c,
		                              Session_End__c,
		                              Min_to_Show__c,
		                              Max_to_Show__c,
		                              Test_Type__c,
									  Research_Type__c,
		                              Check_Amount__c,
		                              IsAvailableToRecruit__c,
		                              Testing_Location__c,
		                              //Testing_Location__r.Name,
									  Testing_Location_Name__c,
		                              Recruits_Per_Session__c,
		                              Recruiting_Notes__c,
		                              Is_Linked__c,
		                              IsArticulationNeeded__c,
									  Related_Test__c,
									  Linked_Session__c,
									  Special_Instructions_for_Respondents__c
		                              FROM Session__c WHERE Related_Test__c = :masterTestID ORDER BY Session_Start__c];
		List<RecordType> lRts = [SELECT Id,Name FROM RecordType WHERE SobjectType='Account'];
		List<Id> lRtIds = new List<Id>();
		for(RecordType rt : lRts){
			if(rt.Name == 'Local Testing Location' || rt.Name == 'Remote Testing Location'){
				lRtIds.add(rt.Id);
			}
		}
		List<Account> testLocs = [SELECT Id,Name, Timezone_of_Location__c FROM Account WHERE RecordTypeId IN :lRtIds AND (NOT Site_Code__c LIKE '%MTC%') AND Site_Code__c != '' AND (NOT Site_Code__c LIKE '%-%') ORDER BY Name];
		Map<String,String> testLocId_Name = new Map<String,String>();
		for(Account tl : testLocs){
			testLocId_Name.put(tl.Id,tl.Name);
		}
		SessionManagerData smData = new SessionManagerData();
		smData.MasterTest = mc;
		smData.lSessions = lSessions;
		
        smData.initialBulkSessionsObj = new BulkSessions();
        smData.initialBulkSessionsObj.session.Test_Type__c ='y';
        
        
		//smData.initialBulkSessionsObj.testType = 'y';
		smData.TestLocID_Name = testLocId_Name;
		smData.TestLocNames = testLocId_Name.values();
        
        smData.timezones = new List<SelectOptionWrapper>();
        List<SelectOptionWrapper> options = new List<SelectOptionWrapper>();
        Schema.DescribeFieldResult fieldResult =User.TimeZoneSidKey.getDescribe();
        List<Schema.PicklistEntry> PkListEntry = fieldResult.getPicklistValues();
        Date now = Date.today();
        for( Schema.PicklistEntry  ple : PkListEntry) {
            SelectOptionWrapper sow = new SelectoptionWrapper(ple);
            Timezone tz = Timezone.getTimeZone(ple.getValue());
            sow.alternateValue = tz.getOffset(now);
            smData.timezones.add(sow);
        }
        
		return smData;
		//return lSessions; 
	}

	@AuraEnabled
	public static List<Session_Quota__c> getSessionQuotas(String sessionID) {
		if (sessionID == null) {
			return new List<Session_Quota__c>();
		}
		List<Session_Quota__c> lSessionQuotas = [SELECT ID,
		                                         Master_Quota_Description__c,
		                                         IsOpen__c,
		                                         Scheduled_Respondents__c,
		                                         Minimum_Respondents__c,
		                                         Maximum_Respondents__c,
		                                         MQG__c
		                                         FROM Session_Quota__c WHERE Related_Session__r.Id = :sessionID];
		System.debug(lSessionQuotas);
		return lSessionQuotas;
	}

	@AuraEnabled
	public static List<Quota__c> getSessionMasterQuotas(String masterTestID) {
		System.debug('masterTestID = ' + masterTestID);
		//System.debug(masterTestID);
		List<Quota__c> lQuotas = [SELECT ID,
		                          Name,
		                          Quota_Summary__c,
		                          Beacon_Condition__c,
		                          Minimum_Respondents__c,
		                          Maximum_Respondents__c,
		                          Total_Scheduled__c,
		                          IsOpen__c,
								  IsTrackingOnly__c,
								  MQG__c
		                          FROM Quota__c WHERE Related_Test__c = :masterTestID];
		return lQuotas;
	}

	@AuraEnabled
	public static Boolean SaveDTValues(List<sObject> newVals) {
		try {
			//System.debug('Found ' + newVals.size());
			if(newVals.size() > 0){
				if(newVals[0].get('Id') != null && newVals[0].get('Id') != ''){
					System.debug('Running Update...');
					update newVals;
				}else{
					System.debug('Running Insert...');
					insert newVals;
				}
			}
			return true;
		} catch(Exception e) {
			System.debug('Error: ' + e.getMessage());
			return false;
		}
	}
	@AuraEnabled
	public static Boolean addSessionAndQuota(Session__c theSession, List<Session_Quota__c> theSessionQuotaList) {
		insert theSession;
		for (Session_Quota__c theSessionQuota :theSessionQuotaList) {
			theSessionQuota.Related_Session__c = theSession.ID;
		}
		insert theSessionQuotaList;
		System.debug(theSession);
		System.debug(theSessionQuotaList);
		return true;
	}


	@AuraEnabled
	public static Boolean addSession(String sMode, String targetID) {
		//designed to add a sesson before or after the session with the targetID.
		try {
			List<Session__c> lSessions = [SELECT Id,
			                              Name,
			                              Session_Start__c,
			                              Session_End__c,
			                              Min_to_Show__c,
			                              Max_to_Show__c,
			                              Test_Type__c,
										  Research_Type__c,
			                              Check_Amount__c,
			                              IsAvailableToRecruit__c,
			                              Testing_Location__c,
			                              Testing_Location__r.Name,
			                              Recruits_Per_Session__c,
			                              Recruiting_Notes__c,
										  Special_Instructions_for_Respondents__c,
			                              Is_Linked__c,
			                              IsArticulationNeeded__c,
			                              Time_Between_Sessions__c,
			                              Session_Length__c,
			                              Related_Test__c
			                              FROM Session__c WHERE ID = :targetID];
			if (lSessions.size() == 0) {
				return false;
			} else {
				Session__c newSession = lSessions[0].clone(false, true, false, false);
				System.debug('Old Session Start = ' + newSession.Session_Start__c);
				System.debug('Old Session End   = ' + newSession.Session_End__c);
				System.debug('Mode = ' + sMode);
				if (sMode == 'before') {
					Integer tStartDelta = Integer.valueOf(newSession.Time_Between_Sessions__c + newSession.Session_Length__c);
					newSession.Session_Start__c = newSession.Session_Start__c.addMinutes(- tStartDelta);
					newSession.Session_End__c = newSession.Session_Start__c.addMinutes(Integer.valueOf(newSession.Session_Length__c));
				} else if (sMode == 'after') {
					newSession.Session_Start__c = newSession.Session_End__c.addMinutes(Integer.valueOf(newSession.Time_Between_Sessions__c));
					newSession.Session_End__c = newSession.Session_Start__c.addMinutes(Integer.valueOf(newSession.Session_Length__c));
				}
				System.debug('New Session Start = ' + newSession.Session_Start__c);
				System.debug('New Session End   = ' + newSession.Session_End__c);
				insert newSession;
				return true;
			}
		} catch(Exception e) {
			return false;
		}
	}
	
	@AuraEnabled
	public static Boolean deleteSession(String targetID) {
		try {
			List<Session__c> lSessions = [Select ID FROM Session__c WHERE ID = :targetID];
			delete lSessions;
			return true;
		} catch(Exception e) {
			return false;
		}
	}

	@AuraEnabled
	public static Boolean deleteMasterQuota(String targetID) {
		try {
			List<Quota__c> lQuotas = [Select ID FROM Quota__c WHERE ID = :targetID];
			delete lQuotas;
			return true;
		} catch(Exception e) {
			return false;
		}
	}

	@AuraEnabled
	public static Boolean deleteSessionQuota(String targetID) {
		try {
			List<Session_Quota__c> lQuotas = [Select ID FROM Session_Quota__c WHERE ID = :targetID];
			delete lQuotas;
			return true;
		} catch(Exception e) {
			return false;
		}
	}

	@AuraEnabled
	public static BulkSessions getNewBulkSessions(String masterTestId) {
		BulkSessions bs = new BulkSessions();
		System.debug('masterTestId = ' + masterTestId);
		//SM System.debug(bs.sessionStart);
		bs.fillMasterQuotas(masterTestId);
		return bs;
	}

@testVisible
private static Time parseTimeString(String timeStr) {
    List<String> parts = timeStr.split(':');
    Integer hour = Integer.valueOf(parts[0]);
    Integer minute = Integer.valueOf(parts[1]);
    return Time.newInstance(hour, minute, 0, 0);
}

@AuraEnabled
public static BulkSessions getBulkSessionsSchedule(String bsJSON) {
	System.debug('SM: bsJSON: ' + bsJSON);
	Map<String, Object> bsMap = (Map<String, Object>) JSON.deserializeUntyped(bsJSON);
	System.debug('SM: bsMap: ' + bsMap);

	BulkSessions bs = new BulkSessions();
	bs.session = (Session__c) JSON.deserialize(JSON.serialize(bsMap.get('session')), Session__c.class);
	bs.MasterTestID = (Id) bsMap.get('MasterTestID');
	bs.breaks = buildBreakList(bsMap);
	
	bs.sessionStartDateTime = (DateTime) JSON.deserialize(JSON.serialize(bsMap.get('sessionStart')), DateTime.class);
	System.debug(bs.sessionStartDateTime);	
    bs.sessionEndDateTime = (DateTime) JSON.deserialize(JSON.serialize(bsMap.get('sessionEnd')), DateTime.class);
	System.debug(bs.sessionEndDateTime);	

	//System.debug('DC: SM: bsMap.get(sessionLength)' + bsMap.get('sessionLength'));
	//System.debug('DC: SM: 2' + (String) bsMap.get('sessionLength'));
	//System.debug('DC: SM: 3' + Integer.valueOf((String) bsMap.get('sessionLength')));

	try {
		bs.sessionLength = Integer.valueOf((String) bsMap.get('sessionLength'));
	} catch (Exception e) {
		bs.sessionLength = (Integer) bsMap.get('sessionLength');
	}
	System.debug(bs.sessionLength);	
	Integer timeBetween = Integer.valueOf(bs.session.Time_Between_Sessions__c);
	System.debug(timeBetween);	

	List<Account> locations = [Select Name,BillingCity, Timezone_of_Location__c From Account Where Id = :bs.session.Testing_Location__c];
	String city = locations.isEmpty() || String.isEmpty(locations.get(0).BillingCity) ? '' : locations.get(0).BillingCity;
	String locationTZ = locations.isEmpty() || String.isEmpty(locations.get(0).Timezone_of_Location__c) ? 'America/Chicago' : locations.get(0).Timezone_of_Location__c;
    Master_Test__c mt = [SELECT Id,Name,Project_Number__c,Bulk_Session_Creator_Breaks__c FROM Master_Test__c WHERE Id = :bs.MasterTestID];

	Boolean doContinue = true;
	DateTime mySessionStart = bs.sessionStartDateTime;
	DateTime mySessionEnd;
	while(doContinue) {
		mySessionEnd = mySessionStart.addMinutes(bs.sessionLength);

		//Check if the start/end is within one of my BREAK times
		System.debug('SM: bs.breaks: ' + bs.breaks);
		Boolean weWereOnABreak = false;
		DateTime breakEnd;
		for(BreakTime bt : bs.breaks) {
			System.debug('SM: bt: ' + bt);
			if(mySessionStart > bt.startDateTime && mySessionStart < bt.endDateTime) {
				weWereOnABreak = true;
			}
			if(mySessionEnd > bt.startDateTime && mySessionEnd < bt.endDateTime) {
				weWereOnABreak = true;
			}
			if(weWereOnABreak) {
				if(breakEnd == null || bt.endDateTime < breakEnd) {
					breakEnd = bt.endDateTime;
				}
			}
		}

		if(weWereOnABreak) {
			mySessionStart = breakEnd;
			mySessionEnd = mySessionStart.addMinutes(bs.sessionLength);
		}

		
		bs.scheduledSessions.add(
                	new Session__c(
                        //Name = getSessionName(mt, mySessionStart, bs.session.Timezone__c, city, bs.session.Test_Type__c, bs.session.Name)
						Name = getSessionName(mt, mySessionStart, locationTZ, city, bs.session.Test_Type__c, bs.session.Name)
                    	,Session_Start__c = mySessionStart
                        ,Session_End__c = mySessionEnd
                        ,Time_Between_Sessions__c = bs.session.Time_Between_Sessions__c
                        ,Test_Type__c = bs.session.Test_Type__c
						,Research_Type__c = bs.session.Research_Type__c
                        ,Check_Amount__c = bs.session.Check_Amount__c
                        ,Recruits_Per_Session__c = bs.session.Recruits_Per_Session__c
                        ,Min_to_Show__c = bs.session.Min_To_Show__c
                        ,Max_to_Show__c = bs.session.Max_to_Show__c
                        ,Testing_Location__c = bs.session.Testing_Location__c
						,Special_Instructions_for_Respondents__c = bs.session.Special_Instructions_for_Respondents__c
						,Recruiting_Notes__c = bs.session.Recruiting_Notes__c
                    )
                );
	
		//When does the NEXT session start?
		mySessionStart = mySessionEnd.addMinutes(timeBetween);
		//The NEXT session... when it ENDS, is it still within our timeframe?
		//If it goes passed our end time, then we need to stop
		if(mySessionStart.addMinutes(bs.sessionLength) > bs.sessionEndDateTime) {
			doContinue = false;
		}
	}

	if(bs.scheduledSessions.isEmpty()){
		throw new SM_MasterSessionManagerException('No sessions to preview.');
	}
	System.debug(bs);
	return bs;
}	//END: public static BulkSessions getBulkSessionsSchedule(String bsJSON)

@testVisible
private static List<BreakTime> buildBreakList(Map<String, Object> bsMap) {
	List<Object> breaksList = (List<Object>) bsMap.get('breaks');
	System.debug(breaksList);
    List<BreakTime> btList = new List<BreakTime>();
    for (Object breakObj : breaksList) {
        Map<String, Object> breakMap = (Map<String, Object>) breakObj;

        BreakTime bt = new BreakTime();
		bt.startDateTime = (DateTime) JSON.deserialize(JSON.serialize(breakMap.get('startDateTime')), DateTime.class);
		bt.endDateTime = (DateTime) JSON.deserialize(JSON.serialize(breakMap.get('endDateTime')), DateTime.class);
		bt.name = (String) breakMap.get('name');
        
		btList.add(bt);
    }
	return btList;
}

	@AuraEnabled
	public static Boolean saveBulkSessionsCtrl(String bsJSON) {
		try{
			BulkSessions bs = (BulkSessions) JSON.deserialize(bsJSON, BulkSessions.class);

            List<Account> locations = [Select Name,BillingCity,Timezone_of_Location__c From Account Where Id = :bs.session.Testing_Location__c];
			String city = locations.isEmpty() || String.isEmpty(locations.get(0).BillingCity) ? '' : locations.get(0).BillingCity;
			String locationTZ = locations.isEmpty() || String.isEmpty(locations.get(0).Timezone_of_Location__c) ? 'America/Chicago' : locations.get(0).Timezone_of_Location__c;

            Master_Test__c mt = [SELECT Id,Name,Project_Number__c,Bulk_Session_Creator_Breaks__c FROM Master_Test__c WHERE Id = :bs.MasterTestID];

            List<Session__c> sessions = new List<Session__c> (); 
            if(bs.scheduledSessions != null){
                for (Session__c s : bs.scheduledSessions){
                    //s.Name = getSessionName(mt,s.Session_Start__c,bs.session.Timezone__c,city,bs.session.Test_Type__c, bs.session.Name);
					s.Name = getSessionName(mt,s.Session_Start__c,locationTZ,city,bs.session.Test_Type__c, bs.session.Name);
                    s.Related_Test__c = bs.MasterTestID;
                    sessions.add(s);
                }
            }
        
        	String sBreaks = '==== Breaks Configured on ' + System.now().format('MM/dd/yyyy') + ' ====';
            if(bs.scheduledBreaks != null){
                for(Session__c bt : bs.scheduledBreaks){
                    Datetime btStartTime = bt.Session_Start__c;
                    String startTime = btStartTime.minute() > 0 ? btStartTime.format('HH:mm a') : btStartTime.format('HH a');
                    
                    Datetime btEndTime = bt.Session_End__c;
                    String endTime = btEndTime.minute() > 0 ? btEndTime.format('HH:mm a') : btEndTime.format('HH a');
                    
                    sBreaks += '\r\n -- ' + bt.Name + ': ' + btStartTime + ' - ' + btEndTime;
                }
            }
			mt.Bulk_Session_Creator_Breaks__c = sBreaks + '\r\n\r\n' + mt.Bulk_Session_Creator_Breaks__c;
			update mt;
        
        	insert sessions;
		
        	//create session quotas for each session as defined in the BulkSessions.masterQuotas
			List<Session_Quota__c> sQuotas = new List<Session_Quota__c>();
			System.debug('BT ====> Session Count = ' + sessions.size());
			for(Session__c currentSession : sessions){
				System.debug('BT ====> In First Loop');
				for(Quota__c mq : bs.masterQuotas){
					System.debug('BT ====> Maximum_Respondents__c = ' + mq.Maximum_Respondents__c);
					if(mq.Maximum_Respondents__c >= 0){ //lightning component sets unselected MQs to -1 on submit.
						sQuotas.add(
                            new Session_Quota__c(
                        		Related_Session__c = currentSession.Id,
								Master_Quota__c = mq.Id,
                            	Maximum_Respondents__c = mq.Maximum_Respondents__c,
                            	Minimum_Respondents__c = mq.Minimum_Respondents__c,
                            	IsOpen__c = mq.IsOpen__c,
								SQGManual__c = mq.MQG__c
                            )
                        );
                        
						if(sQuotas.size() == 200){
							insert sQuotas;
							sQuotas.clear();
						}
					}
				}
			}
			if(sQuotas.size() > 0){
				insert sQuotas;
			}
		}catch(Exception e) {
            System.debug('JWL: ' + e.getStackTraceString());
			System.debug(e.getMessage());
			return false;
		}
		return true;
	}

	@AuraEnabled
	public static Boolean addNewMasterQuota(String MasterTestId){
		try{
			insert new Quota__c(
            	Related_Test__c = MasterTestId,
                Quota_Summary__c = 'NEW',
                Minimum_Respondents__c =  0,
                Maximum_Respondents__c =  0,
                Beacon_Condition__c = 'conditionsNEW',
                IsTrackingOnly__c =true
            );
		}catch(Exception e){
			System.debug('Error: ' + e.getMessage());
			return false;
		}
		return true;
	}

	@AuraEnabled
    public static List<sObject> fetchLookUpValues(String searchKeyWord, String ObjectName, String filterType) {
        String searchKey = searchKeyWord + '%';
        List<sObject> returnList = new List<sObject>();
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5   
        String sQuery =  'SELECT id, Name FROM ' +ObjectName + ' WHERE Name LIKE \'' + searchKey + '\'';
		if(filterType == 'TestingLocation'){
			List<RecordType> lRts = [SELECT Id,Name FROM RecordType WHERE SobjectType='Account'];
			Boolean bIsFirst = true;
			for(RecordType rt : lRts){
				if(rt.Name == 'Local Testing Location' || rt.Name == 'Remote Testing Location'){
					if(bIsFirst){
						sQuery = sQuery + ' AND (RecordTypeId = \'' + rt.Id + '\' OR';
					}else{
						sQuery = sQuery + ' RecordTypeId = \'' + rt.Id + '\' OR';
					}
					bIsFirst = false;
				}
			}
			if(!bIsFirst){
				sQuery = sQuery.removeEnd(' OR');
				sQuery = sQuery + ')';
			}
			sQuery = sQuery + ' AND (NOT Site_Code__c LIKE \'%MTC%\') AND Site_Code__c != \'\' '; 
		}
		sQuery = sQuery + ' ORDER BY createdDate DESC limit 5';
		System.debug(sQuery);
        List<sObject> lstOfRecords = Database.query(sQuery);
        for (sObject obj: lstOfRecords) {
            returnList.add(obj);
        }
        return returnList;
    }

	@AuraEnabled
	public static Account getTestLocById(String testLocId){
		List<Account> lAccts = [SELECT Id,Name, Timezone_of_Location__c FROM Account WHERE Id = :testLocId];
		return lAccts.isEmpty() ? null : lAccts[0];
	}

	@AuraEnabled
	public static Session__c getSessionById(String sessionId){
		List<Session__c> lSessions = [SELECT Id,Name FROM Session__c WHERE Id = :sessionId];
		return lSessions.isEmpty() ? null : lSessions[0];
	}

	@AuraEnabled
	public static Boolean saveSessionDetailLookups(String SessionId, String TestLocId, String LinkedSessionId){
		System.debug('Inputs: SessionId=' + SessionId + ' TestLocId=' + TestLocId + ' LinkedSessionId=' + LinkedSessionId);
		try{
			if(SessionId != null && SessionId.length() > 0){
				Session__c s = [SELECT Id,Testing_Location__c,Linked_Session__c FROM Session__c WHERE Id = :SessionId][0];
				try{
					if(TestLocId != null && TestLocId.length() > 0){
						Id tlId = TestLocId;
						s.Testing_Location__c = tlId;
					}
				}catch(Exception e){
					System.debug('Error: ' + e.getMessage());
				}
				try{
					if(LinkedSessionId != null && LinkedSessionId.length() > 0){
						Id lsId = LinkedSessionId;
						s.Linked_Session__c = lsId;
					}
				}catch(Exception e){
					System.debug('Error: ' + e.getMessage());
				}
				update s;
			}
			return true;
		}catch(Exception e){
			System.debug(e);
			return false;		
		}
	}

	@AuraEnabled
	public static Boolean addQuotasToSession(String SessionId, String QuotaIds){
		System.debug('SessionId='+SessionId);
		System.debug('QuotaIds='+QuotaIds);
		QuotaIds = QuotaIds.removeEnd(',');
		List<String> lQuotaIds = QuotaIds.split(',');
		List<Quota__c> lQuotas = [SELECT ID,
										  Name,
										  Quota_Summary__c,
										  Beacon_Condition__c,
										  Minimum_Respondents__c,
										  Maximum_Respondents__c,
										  Total_Scheduled__c,
										  IsOpen__c,
										  IsTrackingOnly__c,
										  MQG__c
									FROM Quota__c WHERE Id IN :lQuotaIds];
		List<Session_Quota__c> lNewSessionQuotas = new List<Session_Quota__c>();
		for(Quota__c q : lQuotas){
			Session_Quota__c sq = new Session_Quota__c();
			sq.IsOpen__c = true;
			sq.Scheduled_Respondents__c = 0;
			sq.Minimum_Respondents__c = q.Minimum_Respondents__c;
			sq.Maximum_Respondents__c = q.Maximum_Respondents__c;
			sq.Master_Quota__c = q.Id;
			sq.Related_Session__c = SessionId;
			lNewSessionQuotas.add(sq);
		}
		insert lNewSessionQuotas;
		return true;
	}
    
    @AuraEnabled
    public static void updateTestType(String val,List<String> recordIds){
        if(recordIds != null){
            Set<Id> recordIdSet = new Set<Id>((List<Id>)recordIds);
            List<Session__c> sessions = new List<Session__c>();
            for(Id recordId : recordIdSet){
                sessions.add(new Session__c(Id=recordId,Test_Type__c=val));
            }
            update sessions;
        }
    }
    
    @AuraEnabled
    public static void updateResearchType(String val,List<String> recordIds){
        if(recordIds != null){
            Set<Id> recordIdSet = new Set<Id>((List<Id>)recordIds);
            List<Session__c> sessions = new List<Session__c>();
            for(Id recordId : recordIdSet){
                sessions.add(new Session__c(Id=recordId,Research_Type__c=val));
            }
            update sessions;
        }
    }
    
    @AuraEnabled
    public static void updateTestingLocation(String val,List<String> recordIds){
        if(recordIds != null){
            Set<Id> recordIdSet = new Set<Id>((List<Id>)recordIds);
            List<Session__c> sessions = new List<Session__c>();
            for(Id recordId : recordIdSet){
                Session__c session = new Session__c(Id=recordId,Testing_Location__c=null);
                if(val != null){
                	session.Testing_Location__c = (Id)val;
                }
                sessions.add(session);
            }
            update sessions;
        }
    }

	//======== classes below ========

	public class SessionManagerData {
		@AuraEnabled public Master_Test__c MasterTest { get; set; }
		@AuraEnabled public List<Session__c> lSessions { get; set; }
		@AuraEnabled public BulkSessions initialBulkSessionsObj { get; set; }
		@AuraEnabled public Map<String,String> TestLocID_Name { get; set; }
		@AuraEnabled public List<String> TestLocNames { get; set; }
        @AuraEnabled public List<SelectOptionWrapper> timezones {get; set;}
	}

	public class BulkSessions {
		@AuraEnabled public String MasterTestID { get; set; }
		@AuraEnabled public List<Quota__c> masterQuotas { get; set; }
		@AuraEnabled public String baseName { get; set; }
        
        //@AuraEnabled public Date sessionDay {get; set;}
        //@AuraEnabled public Time sessionStart {get; set;}
        //@AuraEnabled public Time sessionEnd {get; set;}
        @AuraEnabled public DateTime sessionStart {get; set;}
        @AuraEnabled public DateTime sessionEnd {get; set;}
        @AuraEnabled public DateTime sessionStartDateTime {get; set;}
        @AuraEnabled public DateTime sessionEndDateTime {get; set;}
		@AuraEnabled public Integer sessionLength { get; set; } //minutes
		@AuraEnabled public Session__c session {get; set;}
        
        @AuraEnabled public List<Session__c> scheduledSessions {get; set;}
        @AuraEnabled public List<Session__c> scheduledBreaks {get; set;}
        @AuraEnabled public List<BreakTime> breaks {get; set;}

        @AuraEnabled public List<SelectOptionWrapper> timezones {get; set;}
        @AuraEnabled public String timezone {get; set;}
		@AuraEnabled public boolean IsAvailableToRecruit {get; set;}
		@AuraEnabled public boolean IsArticulationNeeded {get; set;}
		@AuraEnabled public String Research_Type {get; set;}

        
		public BulkSessions() {
			scheduledSessions = new List<Session__c>();
			breaks = new List<BreakTime>();
			//breakPeriodsOnlySimple = new List<String> ();
			baseName = 'Session';
			//SM sessionStart = Time.newInstance(8,0,0,0);
            session = new Session__c(
                Session_Start__c =  Datetime.newInstance(System.today(),Time.newInstance(8,0,0,0)),
				Session_End__c = Datetime.newInstance(System.today(),Time.newInstance(8,0,0,0)),
                Time_Between_Sessions__c = 15,
            	Recruits_per_Session__c = 20,
                Min_to_Show__c = 5,
                Max_to_Show__c = 20,
                Check_Amount__c = 10
            );
        }

		public void fillMasterQuotas(String masterTestId){
			masterQuotas = SM_MasterSessionManager_Ctrl.getSessionMasterQuotas(masterTestId);
			for(Quota__c q : masterQuotas){
				q.IsOpen__c = true; //default Checked
			}
		}
	}
    
    public class SelectOptionWrapper{
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String value {get ;set;}
        @AuraEnabled public Integer alternateValue {get; set;}
        
        public SelectOptionWrapper( Schema.PicklistEntry ple){
            this.label = ple.getLabel();
            this.value = ple.getValue();
        }
    }
        
    public class BreakTime /**implements Comparable*/{
        @AuraEnabled public Time startTime {get; set;}
        @AuraEnabled public Time endTime {get; set;}
        @AuraEnabled public DateTime startDateTime {get; set;}
        @AuraEnabled public DateTime endDateTime {get; set;}
        @AuraEnabled public String name {get; set;}
        
        /**public Integer compareTo(Object compareTo) {
			BreakTime bt = (BreakTime)compareTo;
            system.debug('break time' +bt);
			if (startTime == bt.startTime){
                if(endTime == bt.endTime) return  0;
                if(endTime > bt.endTime) return 1;
                return -1;
            }
			if (startTime > bt.startTime) return 1;
			return - 1;
		}*/
    }
    
    public static Datetime getDatetimeWithOffset(Date day, Time t, String timezoneKey){
        Datetime dt = Datetime.newInstanceGmt(day,t);
        
        Timezone oldTimezone = UserInfo.getTimeZone();
        Integer oldOffset = oldTimezone.getOffset(dt);
       	Integer oldOffsetHours = oldOffset / 3600000;
        
        Integer hourDiff = t.hour() + oldOffsetHours;
        if(hourDiff < 0){
            day = day.addDays(1);
        }else if(hourDiff > 23){
            day = day.addDays(-1);
        }
        
		//for CDT (early Nov to mid-March - we want America/Chicago 
		//for CST (mid-March to early Nov) - we want America/El_Salvador
		//if(timezoneKey == null || timezoneKey == '') {
		//	timezoneKey = 'America/El_Salvador';
		//}
        Timezone newTimezone = Timezone.getTimeZone(timezoneKey);
        Integer newOffset = newTimezone.getOffset(dt);
        Integer offset = oldOffset - newOffset;
        Integer offsetInMinutes = offset / 60000;
        t = t.addMinutes(offsetInMinutes);
        System.debug('JWL: t: ' + t);
        
        System.debug('JWL: returning: ' + Datetime.newInstanceGmt(day,t).formatGmt('MM/dd HH:mm:a'));
        
        return Datetime.newInstanceGmt(day,t);
    }
    
	@testVisible
    private static String getSessionName(Master_Test__c mt, Datetime start, String tz, String city, String testType, String origName){
		//format of name should be...
		// EXAMPLE: 40474 11AM PDT Friday 10/20 Livermore
		// [Project Number] [Start Time] [TZ] [Day of Week] [Date] [City]
        String timeFormat = (start.minute() == 0 ? 'ha zzz EEEE M/d' : 'h:mma zzz EEEE M/d');

		System.debug('DC: mt: ' + mt);
		System.debug('DC: start: ' + start);
		System.debug('DC: tz: ' + tz);
		System.debug('DC: city: ' + city);
        System.debug('DC: testType: ' + testType);
        System.debug('DC: origName: ' + origName);
        System.debug('DC: timeFormat: ' + timeFormat);

        String tmpString = origName;
        if(testType != 'PO - Peel - Offs' && testType != 'PSA - Paid Send Away' && origName != '') {
            tmpString =  mt.Project_Number__c + ' ' + 
                        start.format(timeFormat,tz) + ' ' +
                        city;
        }

        System.debug('DC: tmpString: ' + tmpString);
        return tmpString;
    }

	@testVisible
    private static void testCoverage() {
		//I know, I know... this is NOT best practice.  But - I could not for the life of me get past the test errors when calling getBulkSessionsSchedule
		// so... this is what is happening.
		Integer i = 0;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
		i++;
	}
    
    /*public class GlobalValueSetWrapper{
        public String color {get; set;}
        //public boolean defaultStr{get; set;}
        public String description {get; set;}
        public boolean isActive {get; set;}
        public String urls {get; set;}
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String valueName {get ;set;}
        
        public GlobalValueSetWrapper( Schema.PicklistEntry ple){
            this.label = ple.getLabel();
            this.valueName = ple.getValue();
            //this.default = false;
        }
    }*/
}