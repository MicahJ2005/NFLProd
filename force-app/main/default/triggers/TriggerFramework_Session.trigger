trigger TriggerFramework_Session on Session__c (before insert, before update, after delete, after insert, after undelete, after update) {

/**
*   {Purpose}  �  Wrapper trigger for all functions on Session Quota - all business logic is to be placed in referenced
*               classes and only routing logic is to be created here.
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name                    Description
*   20140926    Andy Boettcher DCS      Created
*   20140114    Andy Boettcher DCS      Sandbox Refresh, re-add
*   =============================================================================
*/
    /** 
    if(trigger.isBefore){
        Timezone currentTimezone = UserInfo.getTimeZone();
        system.debug('DC: currentTimezone: ' + currentTimezone);
        
        Set<Id> accountIds = new Set<Id>();
        Set<Id> masterTestIds = new Set<Id>();
        for(Session__c session : Trigger.new){
            if(session.Testing_Location__c != null){
            	accountIds.add(session.Testing_Location__c);
            }
            
            masterTestIds.add(session.Related_Test__c);
        }
        
        Map<Id,Account> testingLocationMap = new Map<Id,Account>([Select Id,BillingCity From Account Where Id in :accountIds]);
        Map<Id,Master_Test__c> masterTestMap = new Map<Id,Master_Test__c>([Select Id,Project_Number__c From Master_Test__c Where Id in :masterTestIds]);
        
        for(Session__c session : Trigger.new){
            Session__c oldSession = Trigger.isUpdate ? Trigger.oldMap.get(session.Id) : null;
            
			System.debug('DC2: session.Session_Start__c: ' + session.Session_Start__c);
            System.debug('DC2: session.Timezone__c: ' + session.Timezone__c);
            
            
            //If the testType is PO or PSA - don't rename
            if(Trigger.isInsert || oldSession.Testing_Location__c != session.Testing_Location__c){
                if(session.Test_Type__c != 'PO - Peel - Offs' && session.Test_Type__c != 'PSA - Paid Send Away') {
                    session.Name = '';
                    Master_Test__c mt = masterTestMap.get(session.Related_Test__c);
                    if(mt != null){
                        session.Name += mt.Project_Number__c;
                    }
                    
                    String tz = 'America/Chicago';
                    system.debug('DC: session.Timezone__c: ' + session.Timezone__c);
                    if(!String.isEmpty(session.Timezone__c)){
                        tz = session.Timezone__c;
                        system.debug('DC: tz: ' + tz);
                    }

                    try {
                        //String timeFormat = (session.Session_Start__c.minute() == 0 ? ' ha zzz EEEE M/d' : ' h:mma zzz EEEE M/d');
                        //don't want timezone in the name...
                        String timeFormat = (session.Session_Start__c.minute() == 0 ? ' ha EEEE M/d' : ' h:mma EEEE M/d');
                        session.Name += session.Session_Start__c.format(timeFormat,tz);
                    } catch (Exception e) {}

                    
                    Account location = testingLocationMap.get(session.Testing_Location__c);
                    if(location != null && !String.isEmpty(location.BillingCity)){
                        session.Name += ' ' + location.BillingCity;
                    }
                }
            }
                        
           	if(!String.isEmpty(session.Timezone__c)){
                Timezone newTimezone = Timezone.getTimeZone(session.Timezone__c);
                
                System.debug('DC: session.Timezone__c: ' + session.Timezone__c);
                
                
                if(session.Session_Start__c != null && 
                   (oldSession == null || 
                    oldSession.Session_Start__c != session.Session_Start__c || 
                    oldSession.Timezone__c != session.Timezone__c)){
                        
                        Integer newOffsetMilliseconds = newTimezone.getOffset(session.Session_Start__c);
                        Integer oldOffsetMilliseconds = currentTimezone.getOffset(session.Session_Start__c);
                        Integer offsetMinutes = ((oldOffsetMilliseconds - newOffsetMilliseconds) / 60000);
                        session.Session_Start__c = session.Session_Start__c.addMinutes(offsetMinutes);    
                    }
                
                if(session.Session_End__c != null && 
                   (oldSession == null || 
                    oldSession.Session_End__c != session.Session_End__c || 
                    oldSession.Timezone__c != session.Timezone__c)){
                        Integer newOffsetMilliseconds = newTimezone.getOffset(session.Session_End__c);
                        Integer oldOffsetMilliseconds = currentTimezone.getOffset(session.Session_End__c);
                        Integer offsetMinutes = ((oldOffsetMilliseconds - newOffsetMilliseconds) / 60000);
                        session.Session_End__c = session.Session_End__c.addMinutes(offsetMinutes);
                    }
                }
        }
    }
*/
    // Create Map of APEX Trigger Settings
    Map<String, Boolean> mapAPEXSettings = UtilityMethods.CODE_SETTINGS();
    //Boolean isTriggerOn = mapAPEXSettings.get('TriggerFramework_Session_After');
	Boolean isTriggerOn = true;
    if(trigger.isAfter && isTriggerOn) {

        ///////////////////////////
        // Amazon SQS
        ///////////////////////////
        UtilityMethods.sendSAPITriggerWrapper('FPISession'); 

        // Master Test Rollups
        Set<Id> setMTScope = new Set<Id>();
        if(trigger.isDelete) {
        	for(Session__c objSession : trigger.old) {
        		setMTScope.add(objSession.Related_Test__c);
        	}
        } else {
        	for(Session__c objSession : trigger.new) {
        		setMTScope.add(objSession.Related_Test__c);
        	}
        }

        List<Master_Test__c> lstUpdateMT = new List<Master_Test__c>();
        Set<String> setExcludedTypes = new Set<String>();
        setExcludedTypes.add('BN - Bonus');
        setExcludedTypes.add('PSA - Paid Send Away');

        //01.26.2021 - excluded "Invalid Session" from these items.
        for(AggregateResult objAR : [SELECT Related_Test__c, Count(Id) RecCount, MIN(Session_Start__c) FirstSession, MAX(Session_Start__c) LastSession, SUM(Validation_Goal_Set__c) ValGoals FROM Session__c 
                WHERE Related_Test__c = :setMTScope 
                AND Test_Type__c NOT IN :setExcludedTypes 
                AND Invalid_Session__c = false
                GROUP BY Related_Test__c]) {
        	Master_Test__c objMT = new Master_Test__c(Id=(Id)objAR.get('Related_Test__c'));
        	objMT.Number_of_Sessions__c = Integer.valueOf((Decimal)objAR.get('RecCount'));
            objMT.Validation_Recruiting_Goals__c = Integer.valueOf((Decimal)objAR.get('ValGoals'));
        	objMT.First_Session_Start__c = (DateTime)objAR.get('FirstSession');
        	objMT.Last_Session_Start__c = (DateTime)objAR.get('LastSession');
        	lstUpdateMT.add(objMT);
        }

        if(!lstUpdateMT.isEmpty()) {
        	update lstUpdateMT;
        }

    }
}