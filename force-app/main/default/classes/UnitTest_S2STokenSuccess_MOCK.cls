@isTest
public class UnitTest_S2STokenSuccess_MOCK implements HttpCalloutMock {

    public HttpResponse respond(HttpRequest req) {

		HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        res.setBody('{ "access_token" : "SESSION_ID_REMOVED" }');
        res.setStatusCode(200);
        return res;
	}
}