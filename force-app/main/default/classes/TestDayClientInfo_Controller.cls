public with sharing class TestDayClientInfo_Controller {
	public static void doNothing() {}
	/**
	public Task_Queue__c tskQ {get;set;}
	public List<hClsTestDayInfo> lstHcls {get;set;}
	public Contact cont {get;set;}
	public String strUrl {get;set;}
	public String strTime {get;set;}
	public Test_Lead_Information__mdt testlead {get;set;}
    public Task_Queue__c tskM {get;set;}
    private id idMT;
    
	public TestDayClientInfo_Controller(ApexPages.StandardController stdController) {
        Try{
            // STEP 1:  PULL ID FROM STANDARDCONTROLLER
            String objectName = UtilityMethods.findObjectNameFromRecordIdPrefix(stdController.getId());
            
            List<Session__c> lstSessions = new List<Session__c>();
		Decimal dTime;
		//this.idMT = stdController.getRecord().getSObjectType().getDescribe().getName();
		//this.tskQ = (Task_Queue__c)stdController.getRecord();
		if(objectName == 'Task_Queue__c') {
                this.tskQ = (Task_Queue__c)stdController.getRecord();
            String tqId = this.tskQ.Id;
		tskQ = [SELECT Id
						,Project_Name__c
						,Master_Test__c
						,Master_Test__r.Total_Number_of_Respondents__c
						,Location__r.Driving_Directions_and_Hotel_Information__c
						,Master_Test__r.Fielding_Lead_Name__c
						,Location__r.Name
						,Location__r.ShippingStreet
						,Location__r.ShippingCity
						,Location__r.ShippingState
						,Location__r.ShippingPostalCode
						,Location__r.ShippingCountry
						,Location__r.Phone
                		,Location__r.Testing_Location_Street__c
                		,Location__r.Testing_Location_City__c 
                		,Location__r.Testing_Location_State__c
                		,Location__r.Testing_Location_Zip_Postal_Code__c
					FROM Task_Queue__c 
					WHERE Id = :tqId];
		if(tskQ.Master_Test__r.Fielding_Lead_Name__c != null){
			testlead = [SELECT MasterLabel, Email__c, Phone__c FROM Test_Lead_Information__mdt WHERE MasterLabel = :tskQ.Master_Test__r.Fielding_Lead_Name__c];
		}
		strUrl = 'http://www.weather.com/weather/today/'+ tskQ.Location__r.ShippingPostalCode;

		lstHcls = createSessionData(tskQ.Master_Test__c);
		dTime = [SELECT Session_Length__c FROM Session__c WHERE Related_Test__c =:tskQ.Master_Test__c LIMIT 1].Session_Length__c;
		strTime = String.valueOf(dTime);
        }else if(objectName == 'Master_Test__c') {
                idMT = stdController.getId();
        }
        }catch(exception ex){
        }
                this.idMT = stdController.getId();
	}

	public static List<hClsTestDayInfo> createSessionData(Id masterTestId){
		List<Session__c> lstSession = new List<Session__c>();
		List<hClsTestDayInfo> lstSesData = new List<hClsTestDayInfo>();
		Set<Date> setDates = new Set<Date>();
		Integer i = 0;
		Integer x = 0;

		lstSession = [SELECT Id
						,Name
						,Session_Length__c
						,Session_Start__c
					FROM Session__c 
					WHERE Related_Test__c =:masterTestId
					ORDER BY Session_Start__c];

		for(Session__c sDay: lstSession){
			setDates.add(sDay.Session_Start__c.Date());
		}
		for(Date d:setDates){
			List<hClsSession> lstHelperSes = new List<hClsSession>();
			hClsTestDayInfo hDay = new hClsTestDayInfo();
			x+=1;
			i = 0;
			String dname = 'Day '+ x;
			for(Session__c s: lstSession){
				if(d == s.Session_Start__c.Date()){
					i += 1;
					hClsSession hSession = new hClsSession();
					String sName = s.Name;//'Session ' + i;
					String sTime = String.valueOf(s.Session_Start__c.Time());
					hSession.sessionName = sName;
					hSession.sessionTime = sTime;
					lstHelperSes.add(hSession);
				}
			}
			hDay.dayName = dname;
			hDay.lstSes = lstHelperSes;
			lstSesData.add(hDay);
		}

		return lstSesData;
	}

	public class hClsTestDayInfo{
		public String dayName {get;set;}
		public List<hClsSession> lstSes {get;set;}
	}
	public class hClsSession{
		public String sessionName{get;set;}
		public String sessionTime{get;set;}
	}
    public void MT_Drive (){
        List<Task_Queue__c> lstMT = [select 
                     test_location__c
                     FROM Task_Queue__c
                      WHERE Master_Test__c = :idMT AND Name = 'Auto - Fielding Test Summary'
                     ];
            tskM = lstMT[0];
    }
	*/
}