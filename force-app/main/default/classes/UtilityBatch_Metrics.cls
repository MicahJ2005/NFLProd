global class UtilityBatch_Metrics implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
	
	global String strQuery;
	global Boolean bolCommitCalc = false;
	global Set<Id> setTestIds;
	global Map<Id, UtilityMethods.hClsSessionQuotaCounts> mapSessionReporting;
	global Map<Id, UtilityMethods.hClsSessionQuotaCounts> mapSReporting;
	global Map<Id, UtilityMethods.hClsSessionQuotaCounts> mapMQReporting;
	
	///////////////////////////
	// Constructor
	///////////////////////////
	global UtilityBatch_Metrics() {
		mapSessionReporting = new Map<Id, UtilityMethods.hClsSessionQuotaCounts>();
		mapSReporting = new Map<Id, UtilityMethods.hClsSessionQuotaCounts>();
		mapMQReporting = new Map<Id, UtilityMethods.hClsSessionQuotaCounts>();

		// Session Quota fields
		strQuery = 'SELECT Id, Screened_Respondents__c, Scheduled_Respondents__c, IsOpen__c, Maximum_Respondents__c, Minimum_Respondents__c, ';
		strQuery+= ' Related_Session__c, Master_Quota__c, Master_Quota__r.IsTrackingOnly__c, CreatedDate, LastModifiedDate, MQG__c, SQG__c, SQGManual__c, IsScheduleEnabled__c, ';

		// Session Fields
		strQuery+= ' Related_Session__r.Id, Related_Session__r.Recruits_Per_Session__c, Related_Session__r.IsAvailableToRecruit__c, Related_Session__r.IsAutoOff__c, Related_Session__r.IsAutoOn__c, ';
		strQuery+= ' Related_Session__r.CreatedDate, Related_Session__r.LastModifiedDate, Related_Session__r.Session_End__c, Related_Session__r.Related_Test__c, ';
		strQuery+= ' Related_Session__r.Name, Related_Session__r.Session_Start__c, Related_Session__r.Testing_Location__c, Related_Session__r.Testing_Location_Name__c, ';
		strQuery+= ' Related_Session__r.Testing_Location_Street__c, Related_Session__r.Testing_Location_City__c, Related_Session__r.Testing_Location_State__c, ';
		strQuery+= ' Related_Session__r.Testing_Location_Postal_Code__c, Related_Session__r.Research_Type__c, Related_Session__r.Linked_Session__c, ';
		strQuery+= ' Related_Session__r.Check_Amount__c, Related_Session__r.IsArticulationNeeded__c, ';

		// Master Quota Fields
		strQuery+= ' Master_Quota__r.Id, Master_Quota__r.Maximum_Respondents__c, Master_Quota__r.Minimum_Respondents__c, Master_Quota__r.IsOpen__c ';
		
		strQuery+= ' FROM Session_Quota__c ';
		strQuery+= ' WHERE Related_Session__r.Related_Test__c IN :setTestIds';
	}
	
	///////////////////////////
	// Start
	///////////////////////////
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(strQuery);
	}

	///////////////////////////
	// Execute
	///////////////////////////
   	global void execute(Database.BatchableContext BC, List<sObject> scope) {

   		System.Debug(Limits.getLimitQueryLocatorRows());
   		Set<Id> setScopeSQs = new Set<Id>();
	
		for(Session_Quota__c objSQ : (List<Session_Quota__c>)scope) {
			setScopeSQs.add(objSQ.Id);
			UtilityMethods.hClsSessionQuotaCounts clsSQCount = new UtilityMethods.hClsSessionQuotaCounts();

			clsSQCount.objSQ = objSQ;
			clsSQCount.objMQ = new Quota__c(
				Id = objSQ.Master_Quota__r.Id,
				Maximum_Respondents__c = objSQ.Master_Quota__r.Maximum_Respondents__c,
				Minimum_Respondents__c = objSQ.Master_Quota__r.Minimum_Respondents__c,
				IsOpen__c = objSQ.Master_Quota__r.IsOpen__c
			);
			clsSQCount.objS = new Session__c(
				Id = objSQ.Related_Session__r.Id,
				Recruits_Per_Session__c = objSQ.Related_Session__r.Recruits_Per_Session__c,
				IsAvailableToRecruit__c = objSQ.Related_Session__r.IsAvailableToRecruit__c,
				IsAutoOff__c = objSQ.Related_Session__r.IsAutoOff__c,
				IsAutoOn__c = objSQ.Related_Session__r.IsAutoOn__c
			);

			mapSessionReporting.put(objSQ.Id, clsSQCount);
			mapSReporting.put(objSQ.Related_Session__r.Id, clsSQCount);
			mapMQReporting.put(objSQ.Master_Quota__r.Id, clsSQCount);
		}

		// Compute and store the Q/PQ/S Counts in Session_Quota
        List<AggregateResult> lstReportingCounts = [
            SELECT 
                Count(Id) RecCount, 
                IsQualified__c, 
                IsScheduled__c, 
                IsPreQualified__c, 
                Session_Quota__c 
            FROM 
                Test_Respondent_Quota__c 
            WHERE 
                isDeleted = false 
                AND isqualified__c = TRUE 
                AND Session_Quota__c IN :setScopeSQs
            GROUP BY 
                Session_Quota__c, 
                IsQualified__c, 
                IsScheduled__c, 
                IsPreQualified__c
        ];

        for(AggregateResult objAR : lstReportingCounts) {

            Id idSQ = (Id)objAR.get('Session_Quota__c');
            Boolean bolQ = (Boolean)objAR.get('IsQualified__c');
            Boolean bolPQ = (Boolean)objAR.get('IsPreQualified__c');
            Boolean bolS = (Boolean)objAR.get('IsScheduled__c');
            Integer intCount = (Integer)objAR.get('RecCount');

            // Qualified TRQs
            if(bolQ && !bolPQ && !bolS) {
                mapSessionReporting.get(idSQ).intQ = intCount;
            }

            // PreQualified TRQs
            if(bolPQ && !bolS) {
                mapSessionReporting.get(idSQ).intPQ = intCount;
            }

            // Scheduled TRQs
            if(bolS && !bolPQ) {
                mapSessionReporting.get(idSQ).intS = intCount;
            }
        }
	}
	
	///////////////////////////
	// Finish and Final DML
	///////////////////////////
	global void finish(Database.BatchableContext BC) {
		
		//List<Session_Quota__c> lstSendSQ = new List<Session_Quota__c>();
		//List<Session__c> lstSendSession = new List<Session__c>();

		List<Session_Quota__c> lstUpdateSQ = new List<Session_Quota__c>();
		List<Session__c> lstUpdateSession = new List<Session__c>();
		List<Quota__c> lstUpdateMQ = new List<Quota__c>();
		List<Master_Test__c> lstUpdateMT = new List<Master_Test__c>();
		Map<Id, UtilityMethods.hClsSessionQuotaCounts> mapMTRollup = new Map<Id, UtilityMethods.hClsSessionQuotaCounts>();

		String strSQSQueueSuffix = '';
        if(UtilityMethods.isSandbox()) {
            strSQSQueueSuffix = 'Dev';
        } else {
            strSQSQueueSuffix = 'Prod';
        }

		System.Debug('Committing Calcs = ' + bolCommitCalc);

		if(!mapSessionReporting.isEmpty() && bolCommitCalc) {

			/*  *****************************************
			*	SESSION QUOTA
			*	****************************************/

			for(Id objId : mapSessionReporting.keyset()) {
				//Session_Quota__c objSQ = new Session_Quota__c(Id=objId);
				Session_Quota__c objSQ = mapSessionReporting.get(objId).objSQ;

				// Fill Base Metrics
				objSQ.Screened_Respondents__c = mapSessionReporting.get(objId).intQ;
	            objSQ.Scheduled_Respondents__c = mapSessionReporting.get(objId).intS;
	            objSQ.Prequalified_Respondents__c = mapSessionReporting.get(objId).intPQ;

	            // Compute On/Off Logic
	            System.Debug('STARTING ON/OFF LOGIC FOR SQ ID : ' + objId);
	            if(mapSessionReporting.get(objId).objS.IsAutoOff__c && !mapSessionReporting.get(objId).bolSQChanged) {
	            	if((mapSessionReporting.get(objId).intS + mapSessionReporting.get(objId).intPQ) >= mapSessionReporting.get(objId).objSQ.Maximum_Respondents__c) {
	            		System.Debug('AUTO-CLOSING SQ ID : ' + objId);
	            		objSQ.IsOpen__c = false;
               			mapSessionReporting.get(objId).bolSQChanged = true;
	            	} 
	            }

	            lstUpdateSQ.add(objSQ);
			}

			if(!lstUpdateSQ.isEmpty()) {
				UtilityMethods.bolPreventSQSQS = true;
				update lstUpdateSQ;
			}

			/*  *****************************************
			*	SESSION
			*	****************************************/
			List<AggregateResult> lstSessionRoll = [
				SELECT 
					SUM(Scheduled_Respondents__c) Scheduled, 
					Related_Session__c
				FROM 
					Session_Quota__c 
				WHERE 
					Related_Session__r.Related_Test__c IN :setTestIds
					AND Master_Quota__r.IsTrackingOnly__c = FALSE
				GROUP BY 
					Related_Session__c
			];

			for(AggregateResult objAR : lstSessionRoll) {
				Session__c objS = new Session__c(Id=(Id)objAR.get('Related_Session__c'));
				objS.Scheduled_Respondents__c = Integer.valueOf((Decimal)objAR.get('Scheduled'));

				// Compute On/Off Logic
				System.Debug('STARTING ON/OFF LOGIC FOR S ID : ' + objS.Id);
				System.Debug(mapSReporting.get(objS.Id));
				if(mapSReporting.get(objS.Id).objS.IsAutoOff__c && !mapSReporting.get(objS.Id).bolSChanged) {
					if(mapSReporting.get(objS.Id).objS.IsAutoOff__c && objS.Scheduled_Respondents__c >= mapSReporting.get(objS.Id).objS.Recruits_Per_Session__c && mapSReporting.get(objS.Id).objS.IsAvailableToRecruit__c) {
		                objS.IsAvailableToRecruit__c = false;
		                mapSReporting.get(objS.Id).bolSChanged = true;
		            }
				}

				lstUpdateSession.add(objS);
			}

			if(!lstUpdateSession.isEmpty()) {
				update lstUpdateSession;
			}

			/*  *****************************************
			*	MASTER QUOTA
			*	****************************************/
			List<AggregateResult> lstMQRoll = [
				SELECT 
					SUM(Scheduled_Respondents__c) Scheduled, 
					Master_Quota__c
				FROM 
					Session_Quota__c 
				WHERE 
					Related_Session__r.Related_Test__c IN :setTestIds
				GROUP BY 
					Master_Quota__c
			];


            //1/9/2019 - Sophia Murphy - getting Session Quotas with no Master Quotas
            // Throwing errors that we can't update without an ID
			for(AggregateResult objAR : lstMQRoll) {
                Id mqID = (Id)objAR.get('Master_Quota__c');

                if(mqID != null)
                {
                	Quota__c objMQ = new Quota__c(Id=mqID);
    				objMQ.Total_Scheduled__c = (Decimal)objAR.get('Scheduled');

    				// Compute On/Off Logic
    				System.Debug('STARTING ON/OFF LOGIC FOR MQ ID : ' + objMQ.Id);
    				System.Debug(mapMQReporting.get(objMQ.Id));
    	            if(!mapMQReporting.get(objMQ.Id).bolMQChanged && mapMQReporting.get(objMQ.Id).objMQ.IsOpen__c) {
    	            	if(objMQ.Total_Scheduled__c >= mapMQReporting.get(objMQ.Id).objMQ.Maximum_Respondents__c) {
    	            		objMQ.IsOpen__c = false;
                   			mapMQReporting.get(objMQ.Id).bolMQChanged = true;
    	            	} 
    	            }

    				lstUpdateMQ.add(objMQ);
                }
			}

			if(!lstUpdateMQ.isEmpty()) {
				update lstUpdateMQ;
			}

			/*  *****************************************
			*	MASTER TEST
			*	****************************************/

			for(Id objId : setTestIds) {
				mapMTRollup.put(objId, new UtilityMethods.hClsSessionQuotaCounts());
			}

			List<AggregateResult> lstMTRoll = [
				SELECT 
					Count(Id) RecCount, 
					Master_Test__c, 
					Screener_Qualification_Result__c, 
					Respondent_Status__c 
				FROM 
					Test_Respondent__c 
				WHERE 
					Master_Test__c IN :setTestIds
					AND Screener_Qualification_Result__c != NULL 
				GROUP BY 
					Master_Test__c, 
					Screener_Qualification_Result__c, 
					Respondent_Status__c
			];

			for(AggregateResult objAR : lstMTRoll) {
				Id idMT = (Id)objAR.get('Master_Test__c');
				String strScreener = (String)objAR.get('Screener_Qualification_Result__c');
				String strRStatus = (String)objAR.get('Respondent_Status__c');
				Integer intRecCount = Integer.valueOf((Decimal)objAR.get('RecCount'));

				// Pull active counts out of Map
				Integer intTotal = mapMTRollup.get(idMT).intTotal;
				Integer intQualified = mapMTRollup.get(idMT).intQ;
				Integer intScheduled = mapMTRollup.get(idMT).intS;

				// First, all Q/DQ count in Total.
				if(strScreener == 'Qualified' || strScreener == 'Disqualified') {
					intTotal+= intRecCount;
				}

				// Second, count only Beacon qualified as "Qualified"
				if(strScreener == 'Qualified') {
					intQualified+= intRecCount;
				}

				// Third, count only Respondent Status of "Scheduled" as such.
				if(strRStatus == 'Scheduled') {
					intScheduled+= intRecCount;
				}

				// Put active counts back in Map
				mapMTRollup.get(idMt).intTotal = intTotal;
				mapMTRollup.get(idMt).intQ = intQualified;
				mapMTRollup.get(idMt).intS = intScheduled;
			}

			for(Id objId : mapMTRollup.keyset()) {
				Master_Test__c objMT = new Master_Test__c(Id=objId);
				objMT.Total_Respondents__c = mapMTRollup.get(objId).intTotal;
	            objMT.Total_Schedule_Respondents__c = mapMTRollup.get(objId).intS;
	            objMT.Total_Qualified_Qr2__c = mapMTRollup.get(objId).intQ;
	            lstUpdateMT.add(objMT);
			}

			if(!lstUpdateMT.isEmpty()) {
				update lstUpdateMT;
			}

			// SQS
			UtilityBatch_MetricAssist clsAssist = new UtilityBatch_MetricAssist();

			if(!lstUpdateSQ.isEmpty()) {
				String strJSONPayloadSQ = UtilityMethods.prepareSAPICalloutPayload('FPIQuota' + strSQSQueueSuffix, 'update', lstUpdateSQ);
				UtilityMethods.hClsMetricAssist clsAssistSQ = new UtilityMethods.hClsMetricAssist();
				clsAssistSQ.strSQSQueue = 'FPIQuota' + strSQSQueueSuffix;
				clsAssistSQ.strJSONPayload = strJSONPayloadSQ;
				clsAssist.lstPayloads.add(clsAssistSQ);
			}

			if(!lstUpdateSession.isEmpty()) {
				String strJSONPayloadSQ = UtilityMethods.prepareSAPICalloutPayload('FPISession' + strSQSQueueSuffix, 'update', lstUpdateSession);
				UtilityMethods.hClsMetricAssist clsAssistSession = new UtilityMethods.hClsMetricAssist();
				clsAssistSession.strSQSQueue = 'FPISession' + strSQSQueueSuffix;
				clsAssistSession.strJSONPayload = strJSONPayloadSQ;
				clsAssist.lstPayloads.add(clsAssistSession);
			}

			if(!clsAssist.lstPayloads.isEmpty()) {
				database.executeBatch(clsAssist, 200);
			}

			//if(!lstUpdateSQ.isEmpty()) {
			//	// Because we can't do callouts... (Batch + Trigger = Blocked!)
			//	String strJSONPayloadSQ = UtilityMethods.prepareSAPICalloutPayload('FPIQuota' + strSQSQueueSuffix, 'update', lstUpdateSQ);
			//	System.Debug('PUSHING to SQS - FPIQuota' + strSQSQueueSuffix + ' - ' + strJSONPayloadSQ);
			//	UtilityMethods.sendSAPICalloutToAmazon('FPIQuota' + strSQSQueueSuffix, strJSONPayloadSQ);
			//}

			//if(!lstUpdateSession.isEmpty()) {
			//	// Because we can't do callouts... (Batch + Trigger = Blocked!)
			//	String strJSONPayloadSession = UtilityMethods.prepareSAPICalloutPayload('FPISession' + strSQSQueueSuffix, 'update', lstUpdateSession);
			//	System.Debug('PUSHING to SQS - FPISession' + strSQSQueueSuffix + ' - ' + strJSONPayloadSession);
			//	UtilityMethods.sendSAPICalloutToAmazon('FPISession' + strSQSQueueSuffix, strJSONPayloadSession);
			//}

		}

	}
	
}