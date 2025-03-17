@isTest
public class UnitTest_SNSSuccess_MOCK implements HttpCalloutMock {

    public HttpResponse respond(HttpRequest req) {

		HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/xml');

        res.setBody('<MessageId>ABC123456789-987654321CBA</MessageId>');
        res.setStatusCode(200);
        return res;
	}
    
}