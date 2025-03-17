global class Invocable_RespondentSetPassword {

    @InvocableMethod
    public static List<String> runSetPassword(List<String> emailAndPW) {

        system.debug('DC: emailAndPW' + emailAndPW);

        //Invocable methods only support one parameter
        Http httpProtocol = new Http();
        HttpRequest req =  new HttpRequest();

        
        String emailWithPw = emailAndPW[0];
        system.debug('DC: emailWithPw ' + emailWithPw );

        //TESTING
        //String email = 'morgan.catlin+107192@valtira.net';
        //String pw = 'letmein';
        String email = emailWithPw.split(';')[0];
        String pw = emailWithPw.split(';')[1];

        List<FPI_AppSettings__c> lstAppSettings = FPI_AppSettings__c.getall().values();
        Map<String, String> mapAppSettings = new Map<String, String>();
        for(FPI_AppSettings__c soAppSetting : lstAppSettings) {
            mapAppSettings.put(soAppSetting.Name, soAppSetting.Value__c);
        }

        // SNS TEST VARS
        String apiKey = mapAppSettings.get('Valtira_SetPassword_APIKey');
        String endpoint = mapAppSettings.get('Valtira_SetPassword_EndPt');
        
        req.setHeader('Content-Type','application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('x-api-key', apiKey);

        //String endpoint = 'https://et6nw3pkzd.execute-api.us-east-2.amazonaws.com/Dev/setpassword';
        
        req.setEndpoint(endpoint);
        req.setMethod('POST');  
        req.setTimeout(100000);
        req.setBody('{"email":"' + email + '", "password":"' + pw + '"}');

        List<String> returnVal = new List<String>();
        if(!Test.isRunningTest()) {
            HttpResponse response = httpProtocol.send(req);
            system.debug(response.getBody());
            returnVal.add(response.getBody());
        }
        
        return returnVal;
    }
 }