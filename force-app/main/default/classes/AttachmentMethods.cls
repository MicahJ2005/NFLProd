public with sharing class AttachmentMethods {
	public static void ReassignAttachments(list<Attachment> lstAttachments){
		for( Attachment a : lstAttachments) {
			// Check the parent ID - if it's 02s, this is for an email message
			if( a.parentid == null )
				continue;
			
			String s = string.valueof( a.parentid );
			
			if( s.substring( 0, 3 ) == '02s' )
				a.parentid = [select WhatId from Task where EmailID__c = :a.parentid].ID;
		}
	}
}