global class UtilityInboundEmail implements Messaging.InboundEmailHandler {
	
	global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email,
																Messaging.InboundEnvelope env) {
 
		// Create an InboundEmailResult object for returning the result of the
		// Apex Email Service

		//for testing, etc - need to see the header values
		try {
		for(Messaging.InboundEmail.Header hdr : email.headers) {
			system.debug(hdr);
		} } catch(Exception e) {}
		
		Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
		
		// Attempt to find the associated Contact
		List<Contact> lstContact = [SELECT Id FROM Contact WHERE Email = :email.FromAddress];

		// Attempt to find a valid Email Handler Custom Setting for the inbound address
		String strInboundAddress = env.ToAddress.substring(0,env.ToAddress.indexOf('@'));
		InboundEmailHandler__c iehEmail = InboundEmailHandler__c.getValues(strInboundAddress);

		if(iehEmail == null) {
			result.success = false;
			result.message = 'No inbound email handler found for this receiever address!  (' + strInboundAddress + ')';
			return result;
		} else {

			// Scan for Included / Excluded Keywords
			Set<String> setExcluded = new Set<String>();
			Set<String> setIncluded = new Set<String>();
			for(InboundEmailFilter__c ief : [SELECT Name, IsExclude__c, IsInclude__c FROM InboundEmailFilter__c]) {
				if(ief.IsExclude__c) { setExcluded.add(ief.Name); }
				if(ief.IsInclude__c) { setIncluded.add(ief.Name); }
			}

			Boolean bolProcessEmail = true;

			// First, check for Exclude
			List<String> lstExcludeWords = email.Subject.split(' ');
			for(String str : lstExcludeWords) {
				if(setExcluded.contains(str)) { bolProcessEmail = false; }
			}

			// Second, if include is on, enable processing
			List<String> lstIncludeWords = email.Subject.split(' ');
			for(String str : lstIncludeWords) {
				if(setIncluded.contains(str)) { bolProcessEmail = true; }
			}

			if(bolProcessEmail) {
				String strHTML = email.FromName + ' (' + email.FromAddress + ')<br /><br />';

				if(email.HtmlBody == null) {
					strHTML+= email.plainTextBody;
				} else {
					strHTML+= email.HtmlBody;
				}
		    	

		    	String strSubject = email.subject;
		    	if(strSubject.length() > 80) {
		    		strSubject = strSubject.substring(0,79);
		    	}

				Task_Queue__c tqNew = new Task_Queue__c();
		    	tqNew.Name = strSubject;
		    	tqNew.Description__c = strHTML;
		    	tqNew.Case_Origin__c = iehEmail.Case_Origin__c;
		    	tqNew.RecordTypeId = UtilityMethods.RECORDTYPE_ID('Task_Queue__c', iehEmail.RT_Name__c);
		    	if(lstContact.size() > 0) { tqNew.Client_Contact__c = lstContact[0].Id; }
		    	insert tqNew;

		    	// Insert Attachments
		    	if (email.binaryAttachments != null && email.binaryAttachments.size() > 0) {
					for (integer i = 0 ; i < email.binaryAttachments.size() ; i++) {
						Attachment attachment = new Attachment();
						// attach to the newly created contact record
						attachment.ParentId = tqNew.Id;
						attachment.Name = email.binaryAttachments[i].filename;
						attachment.Body = email.binaryAttachments[i].body;
						insert attachment;
					}
				}
				
				result.success = true;
			} else {
				result.success = false;
				result.message = 'This email was blocked by Food Perspectives keyword email filters.  Please call Customer Care if you feel this is in error.';
				
			}

			return result;
		}
	}
}