@isTest
public class UnitTest_SNSFailure_MOCK implements HttpCalloutMock {

    public HttpResponse respond(HttpRequest req) {

		HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/xml');

        res.setBody('<Message>User: arn:aws:iam::136561485513:user/sf-sns-demo is not authorized to perform: SNS:Publish on resource: arn:aws:sns:us-east-2:136561485513:FPITestDev</Message>');
        res.setStatusCode(403);
        return res;
	}
    
}