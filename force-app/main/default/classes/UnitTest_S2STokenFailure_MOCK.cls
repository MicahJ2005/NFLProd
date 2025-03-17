@isTest
public class UnitTest_S2STokenFailure_MOCK implements HttpCalloutMock {

    public HttpResponse respond(HttpRequest req) {

		HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        res.setBody('{ "access_token" : "BLARGY BLARG BLARG" }');
        res.setStatusCode(500);
        return res;
	}
}