trigger TriggerFramework_MasterTest on Master_Test__c (after delete, after insert, after undelete, after update) {
    if(trigger.isAfter){

        //Boolean bolSendSQS = false;

		
        ///////////////////////////
        // Amazon SQS
        ///////////////////////////
        UtilitySQS.processSQS('FPITest', 'Master_Test__c', Trigger.oldMap, Trigger.newMap);
        /** Replaced with general field set solution
        if(trigger.isUpdate) {
            Set<String> setFieldsThatMatterToValtira = new Set<String>();
            String strQuery = UtilityMethods.SQS_QUEUES().get('FPITest');
            system.debug('DC: strQuery: ' + strQuery);
            
            for(String strField : strQuery.split(',')) {
                //The last field in the query will come across like this... "Brand__c FROM Master_Test__c"
                // we need to strip the "FROM Master_Test__c" off
                strField = strField.replace(' FROM Master_Test__c', '');
                system.debug('DC: strField: ' + strField);
                if(strField.contains('__c') && !strField.contains('FROM Master_Test__c')) {
                    system.debug('DC: adding field to list');
                    setFieldsThatMatterToValtira.add(strField.trim());
                }
            }

            for(Master_Test__c objMT : trigger.new) {
                for(String strField : setFieldsThatMatterToValtira) {
                    System.Debug('DC: CHECKING ' + strField + ' TO SEE IF O/N ' + trigger.oldMap.get(objMT.Id).get(strField) + ' != ' + objMT.get(strField));
                    if(trigger.oldMap.get(objMT.Id).get(strField) != objMT.get(strField)) {
                        System.Debug('DC: MASTER TEST DETECTED CHANGED VALUE');
                        bolSendSQS = true;
                    }
                }
            }

            System.Debug('SENDING THROUGH TO SQS = ' + bolSendSQS);

        }
        
        if(trigger.isInsert) {
            bolSendSQS = true;
        }

        if(bolSendSQS) {
            UtilityMethods.sendSAPITriggerWrapper('FPITest');
        }
         */
        
    }
}