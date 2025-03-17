@isTest
public class UnitTest_Mock_ValtiraPP implements HttpCalloutMock {

	public HttpResponse respond(HttpRequest req) {

		HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        CheckGeneratorController.valtiraReturnEnvelope clsReturn = new CheckGeneratorController.valtiraReturnEnvelope();
        clsReturn.succeeded = true;

        res.setBody(JSON.serialize(clsReturn));
        res.setStatusCode(200);
        return res;
	}

}