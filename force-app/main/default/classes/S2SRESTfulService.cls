public class S2SRESTfulService{
/**
*   {Purpose}   - Used to communicate between CFS and Covance Drug/Commercial
*                 as an "ETL-Lite" solution
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 952.223.5604               
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name                    Description
*   20171226    Andy Boettcher DCS      Created
*   =============================================================================
*/

    public static String getAccessToken(String orgName){
        List<S2S_Setting__mdt> settings = [SELECT 
                                                Authorization_URI__c,
                                                Token_URI__c,
                                                Callback_URI__c,
                                                Client_Id__c,
                                                Client_Secret__c,
                                                Username__c,
                                                Password__c 
                                            FROM 
                                                S2S_Setting__mdt
                                            WHERE
                                                QualifiedAPIName = :orgName
                                            LIMIT 1
        ];

        S2S_Setting__mdt setting = settings.get(0);
        
        String body = 'grant_type=password&client_id=' 
                        + setting.Client_Id__c 
                        + '&client_secret='
                        + setting.Client_Secret__c
                        + '&redirect_uri='
                        + setting.Callback_URI__c
                        + '&username='
                        + setting.Username__c
                        + '&password='
                        + UtilityMethods.decodeString(setting.Password__c)
                        + '&format=json';
        
        
		Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type','application/x-www-form-urlencoded');
        req.setHeader('Accept', 'application/x-www-form-urlencoded');
        req.setEndpoint(setting.Token_URI__c);
        req.setMethod('POST');
        req.setTimeout(100000);
        req.setBody(body);

        HttpResponse response = h.send(req);
        TokenResponse tr = (TokenResponse)JSON.deserialize(response.getBody(),TokenResponse.class);

        System.Debug(tr);
   		
        return tr.access_token;
    }
    
    public static void upsertRecords(String orgName, String apiName, List<sObject> records, String token, Map<String, String> translationMap){
        
		System.Debug('S2SRESTfulService.upsertRecords START - sending ' + JSON.serialize(records));        
        
        List<S2S_Setting__mdt> settings = [SELECT 
                                                REST_URI__c,
                                                Refresh_Token__c,
                                                (SELECT 
                                                    QualifiedApiName,
                                                    External_Id_Name__c,
                                                    API_Name__c
                                                FROM 
                                                    S2S_Object__r 
                                                WHERE 
                                                    QualifiedApiName = :apiName) 
                                            FROM 
                                                S2S_Setting__mdt 
                                            WHERE 
                                                QualifiedAPIName = :orgName
                                            LIMIT 1

        ];

        S2S_Setting__mdt setting = settings.get(0);
        S2S_Object__mdt upsertObject = setting.S2S_Object__r.get(0);
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type','application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setEndpoint(setting.REST_URI__c);
        req.setMethod('POST');
        req.setTimeout(100000);
        
        UpsertRequest upsertReq = new UpsertRequest();
        upsertReq.records = JSON.serialize(records);
        upsertReq.apiName = upsertObject.API_Name__c;
        upsertReq.externalId = upsertObject.External_Id_Name__c;
        upsertReq.translationMap = translationMap;
        req.setBody(JSON.serialize(upsertReq));  
        
        try{

            HttpResponse response = h.send(req);

        	if(response.getStatusCode() < 200 || response.getStatusCode() > 299) {

                // Complete Audit Trail
                /**  20220707   Sophia Murphy DCS - Commented out, no longer needed
                Automation_Audit_Log__c objAudit = new Automation_Audit_Log__c();
                objAudit.Apex_Source__c = 'S2SRESTfulService.cls';
                objAudit.Apex_Method__c = 'upsertRecords';
                objAudit.Automation_Type__c = 'Apex';
                objAudit.Target_Object__c = upsertObject.API_Name__c;
                objAudit.Details__c = response.getBody();
                objAudit.IsSuccess__c = false;
                insert objAudit;
                */

            } else {
                S2SService.UpsertResponse ur = 
                    (S2SService.UpsertResponse)JSON.deserialize(
                        response.getBody(),S2SService.UpsertResponse.class);
            }

            // Complete Audit Trail
            /**  20220707   Sophia Murphy DCS - Commented out, no longer needed
            
            Automation_Audit_Log__c objAudit = new Automation_Audit_Log__c();
            objAudit.Apex_Source__c = 'S2SRESTfulService.cls';
            objAudit.Apex_Method__c = 'upsertRecords';
            objAudit.Automation_Type__c = 'Apex';
            objAudit.Target_Object__c = upsertObject.API_Name__c;
            objAudit.Details__c = req.getBody() + '\r\n' + response.getBody();
            objAudit.IsSuccess__c = true;
            insert objAudit;
            */

        } catch(Exception e) {

            // Complete Audit Trail
            /**  20220707   Sophia Murphy DCS - Commented out, no longer needed
            Automation_Audit_Log__c objAudit = new Automation_Audit_Log__c();
            objAudit.Apex_Source__c = 'S2SRESTfulService.cls';
            objAudit.Apex_Method__c = 'upsertRecords';
            objAudit.Automation_Type__c = 'Apex';
            objAudit.Target_Object__c = upsertObject.API_Name__c;
            objAudit.Details__c = e.getMessage() + '\r\n' + e.getStackTraceString();
            objAudit.IsSuccess__c = false;
            insert objAudit;
            */

        }
    }
    
    public static void authAndUpsert(String orgName,String apiName, List<sObject> records, Map<String, String> translationMap){
        String accessToken = getAccessToken(orgName);
        upsertRecords(orgName, apiName, records, accessToken, translationMap);
    }
    
    public class UpsertRequest{
        //public List<sObject> records {get; set;}
        public String records {get;set;}
        public String apiName {get; set;}
        public String externalId {get; set;}
        public Map<String, String> translationMap {get; set;}
    }
    
    public class TokenResponse{
        public String access_token {get; set;}
    }
}