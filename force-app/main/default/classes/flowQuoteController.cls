public with sharing class flowQuoteController {
	public static void doNothing() {}
	/** Commented out - no longer needed
	public flowQuoteController(ApexPages.StandardController  controller){}
	public Flow.Interview.CloneQuote ClonedQuote {get;set;}
 	// Factor your PageReference as a full GET/SET
 	public PageReference prFinishLocation {
 		get {
 			system.debug('returnlocation' + strOutputVariable);
			PageReference prRef = new PageReference('/'+strOutputVariable);
 			prRef.setRedirect(true);
 			return prRef;
 		}
 		set { prFinishLocation = value; }
 	}
 // Factor your Flow output variable pull as a full GET / SET
 	public String strOutputVariable {
 		get {
 			String strTemp = '';
			 if(ClonedQuote != null) {
 				strTemp = string.valueOf(ClonedQuote.getVariableValue('ClonedQuoteID'));
 			}
 			system.debug('strTempVariable' + strTemp);
 		return strTemp;
 		}
		set { strOutputVariable = value; }
 	} 
	*/
}