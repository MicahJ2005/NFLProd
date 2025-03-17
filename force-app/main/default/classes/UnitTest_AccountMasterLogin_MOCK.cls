@isTest
public class UnitTest_AccountMasterLogin_MOCK implements HttpCalloutMock{

	public HttpResponse respond(HttpRequest req) {

		HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        res.setBody('{"access_token":"ABC123","instance_url":"https://cs19.salesforce.com","id":"https://test.salesforce.com/id/00D29000000DloxEAC/005C00000049MoBIAU","token_type":"Bearer","issued_at":"1516159140122","signature":"feAIGeEdWcA2IC0H8VXilic5w+l8eeJmVliqUHj+ZuI="}');
        res.setStatusCode(200);
        return res;
	}

}