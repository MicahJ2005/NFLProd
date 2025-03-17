@isTest
public class UnitTest_AccountMasterSearchSuccess_MOCK implements HttpCalloutMock {

    public HttpResponse respond(HttpRequest req) {

		HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
		res.setBody('{"totalSize":1,"done":true,"records":[{"attributes":{"type":"Account","url":"/services/data/v40.0/sobjects/Account/0012900000FAqhmAAD"},"Id":"0012900000FAqhmAAD","Name":"CFS Test Account","Type":null}]}');

		if(req.getEndpoint().contains('Account+WHERE+ParentId')) {
        	res.setBody('{"totalSize":1,"done":true,"records":[{"attributes":{"type":"Account","url":"/services/data/v40.0/sobjects/Account/0012900000FEeLbAAL"},"Id":"0012900000FEeLbAAL","Name":"CFS Test Account 2","Type":null, "ParentId":"0012900000FAqhmAAD"}]}');
        }		

        if(req.getEndpoint().contains('+from+Contact+')) {
        	res.setBody('{"totalSize":2,"done":true,"records":[{"attributes":{"type":"Contact","url":"/services/data/v40.0/sobjects/Contact/0030P00001zVdbkQAC"},"Id":"0030P00001zVdbkQAC","FirstName":"Austin","LastName":"Tagg"},{"attributes":{"type":"Contact","url":"/services/data/v40.0/sobjects/Contact/0030P00001zVeCTQA0"},"Id":"0030P00001zVeCTQA0","FirstName":"Eleni","LastName":"Sami"}]}');
        }
        res.setStatusCode(200);
        return res;
	}
    
}