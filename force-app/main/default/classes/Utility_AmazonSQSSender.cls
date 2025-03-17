public with sharing class Utility_AmazonSQSSender {
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
*   20141001  	Andy Boettcher DCS	    Created
*   =============================================================================
*/


	///////////////////////////
	// Constructors
	///////////////////////////
	public Utility_AmazonSQSSender() {
		
	}

	
	///////////////////////////
	// Action Methods
	///////////////////////////
	public static String getCurrentDate() {
        return DateTime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
    }
    public static String getCurrentDateRaw() {
        return DateTime.now().formatGmt('yyyyMMdd\'T\'HHmmss\'Z\'');
    }
    public static String getCurrentDateOnly() {
        return DateTime.now().formatGmt('yyyyMMdd');
    }

 	public static String sendMessageSignature4(String strSQSQueue, String message) {

     
    List<FPI_AppSettings__c> lstAppSettings = FPI_AppSettings__c.getall().values();
    Map<String, String> mapAppSettings = new Map<String, String>();
    for(FPI_AppSettings__c soAppSetting : lstAppSettings) {
        mapAppSettings.put(soAppSetting.Name, soAppSetting.Value__c);
    }

    // SNS TEST VARS
    String host = mapAppSettings.get('SNSHostName');
    String accessKey = mapAppSettings.get('SNSAccessKey');
    String secretKey = mapAppSettings.get('SNSSecretKey');
    String accountNumber = mapAppSettings.get('SNSAccountNumber');
    String SNSTopicRoot = mapAppSettings.get('SNSTopicRoot');
    String SNSRegionName = mapAppSettings.get('SNSRegionName');
    //String SNSTopic = 'arn:aws:sns:us-east-2:136561485513:SFDemo';
    String SNSARNTopic = SNSTopicRoot + ':' + accountNumber + ':' + strSQSQueue;

    if(host == null) { return 'NO CONNECTION SETTINGS, EXITING SNS'; } 

    String hashAlgo = 'HmacSHA256';
    String url = 'https://'+ host;
    String currentDate = DateTime.now().formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
    String currentDateRaw = DateTime.now().formatGmt('yyyyMMdd\'T\'HHmmss\'Z\'');
    String currentDateOnly = DateTime.now().formatGmt('yyyyMMdd');
    String regionName = SNSRegionName;
    String serviceName = 'sns';

    ////////////////////////////////////
    // BODY
    ////////////////////////////////////

    String strBody = '';
    strBody+= 'AWSAccessKeyId=' + encode(accessKey);
    strBody+= '&Action=Publish';
    strBody+= '&TargetArn=' + encode(SNSARNTopic);
    strBody+= '&Message=' + encode(message);
    strBody+= '&SignatureMethod=' + hashAlgo;
    strBody+= '&SignatureVersion=4';
    strBody+= '&Timestamp=' + encode(currentDate);
    strBody+= '&Version=2010-03-31';
    //strBody+= '&MessageStructure=json';

    ////////////////////////////////////
    // 1 - CANONICAL REQUEST
    ////////////////////////////////////

    String strCanonicalRequest = '';
    strCanonicalRequest+='POST\n';
    strCanonicalRequest+='/\n';
    strCanonicalRequest+='\n';
    strCanonicalRequest+='content-type:application/x-www-form-urlencoded; charset=utf-8\n';
    strCanonicalRequest+='host:' + host + '\n';
    strCanonicalRequest+='x-amz-date:' + currentDate + '\n';
    strCanonicalRequest+='\n';
    strCanonicalRequest+='content-type;host;x-amz-date';
    String strPayloadHash = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(strBody))); // Payload
    strCanonicalRequest+= '\n' + strPayloadHash.toLowerCase();

    ////////////////////////////////////
    // 2 - STRING TO SIGN
    ////////////////////////////////////

    String strStringToSign = '';
    strStringToSign+='AWS4-HMAC-SHA256\n';
    strStringToSign+=currentDateRaw + '\n';
    strStringToSign+=currentDateOnly + '/' + regionName + '/' + serviceName + '/aws4_request';
    String strCanonicalHash = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(strCanonicalRequest))); // Payload
    strStringToSign+= '\n' + strCanonicalHash.toLowerCase();

    ////////////////////////////////////
    // 3 - SIGNATURE
    ////////////////////////////////////

    String kSecret = 'AWS4' + secretKey;
    Blob kDate = Crypto.generateMac(hashAlgo, Blob.valueOf(currentDateOnly), Blob.valueOf(kSecret));
    Blob kRegion = Crypto.generateMac(hashAlgo, Blob.valueOf(regionName), kDate);
    Blob kService = Crypto.generateMac(hashAlgo, Blob.valueOf(serviceName), kRegion);
    Blob kSigning = Crypto.generateMac(hashAlgo, Blob.valueOf('aws4_request'), kService);
    String strSignature = EncodingUtil.convertToHex(Crypto.generateMac(hashAlgo, Blob.valueOf(strStringToSign), kSigning));
    strSignature = strSignature.toLowerCase();

    ////////////////////////////////////
    // 4 - AUTHORIZATION HEADER
    ////////////////////////////////////

    String strAuthorizationHeader = 'AWS4-HMAC-SHA256 ';
    strAuthorizationHeader+= 'Credential=' + accessKey + '/' + currentDateOnly + '/' + regionName + '/' + serviceName + '/aws4_request, ';
    strAuthorizationHeader+= 'SignedHeaders=content-type;host;x-amz-date, ';
    strAuthorizationHeader+= 'Signature=' + strSignature;

    // NOW BUILD THE HTTPREQUEST TO SEND
    HttpRequest req = new HttpRequest();
    req.setEndPoint(url);
    req.setHeader('Authorization', strAuthorizationHeader);
    req.setHeader('content-type','application/x-www-form-urlencoded; charset=utf-8');
    req.setHeader('host', host);
    req.setHeader('x-amz-date', currentDate);
    req.setMethod('POST');
    req.setBody(strBody);

    Http http = new Http();
    String strReturnValue = null;

    if(!Test.isRunningTest()) {
      try {
          HttpResponse res = http.send(req);

          // If Error, handle and return
          if(res.getStatusCode() != 200) { 
              System.Debug(res);
            System.Debug(res.getBody());
            return 'ERROR - SNS MESSAGE SENT BUT WAS NOT SUCCESSFUL'; 
          }

          // If Success, pull MessageId and return
          String strResponse = res.getBody();
          strReturnValue = strResponse.subStringBetween('<MessageId>','</MessageId>');

      }
      catch (System.CalloutException e) {
          System.debug('ERROR: ' + e);
          return 'ERROR - SNS MESSAGE WAS NOT SENT, EXCEPTION THROWN';
      }
    }

    return strReturnValue;

 	}

    public static String encode(String message){
        try {
            return EncodingUtil.urlEncode(message,'UTF-8').replace('+', '%20').replace('*', '%2A').replace('%7E','~');    
        } catch(Exception ex) {
            return '';
        }
    }

}