/**
*   {Purpose}  �  Provide Unit Test Coverage for UtilityMethods and UtilityGlobalMethods
*
*   {Contact}   - support@demandchainsystems.com
*                 www.demandchainsystems.com
*                 612-424-0032                  
*/

/**
*   CHANGE  HISTORY
*   =============================================================================
*   Date        Name                    Description
*   20140313    Andy Boettcher DCS      Created
*   20141125    Andy Boettcher DCS      Added new method to cover UtilityGlobalMethods
*	20200317	Sophia Murphy DCS		Added lots of calls to get overage on UtilityMethods up.
*   =============================================================================
*/
@isTest
private class UnitTest_cls_UtilityMethods {
    
    @isTest static void testUtilityMethods() {

        UnitTest_Test_Data.commitFPIApexSettings();
        
        //FPI_AppSettings__c csAppSetting = UnitTest_Test_data.BuildFPI_AppSettings('test', 'test');
        //insert csAppSetting;

        //List<Zip_Code_Zones__c> lstZips = new List<Zip_Code_Zones__c>();
        //lstZips.add(new Zip_Code_Zones__c(Name='12345',Zone__c='Southwest'));
        //lstZips.add(new Zip_Code_Zones__c(Name='12346',Zone__c='Southwest'));
        //lstZips.add(new Zip_Code_Zones__c(Name='12347',Zone__c='Southwest'));
        //lstZips.add(new Zip_Code_Zones__c(Name='12348',Zone__c='Southwest'));
        //lstZips.add(new Zip_Code_Zones__c(Name='12349',Zone__c='Southwest'));
        //insert lstZips;

        test.startTest();

            Map<String, Boolean> mapCodeSettings = UtilityMethods.CODE_SETTINGS();
            Map<String, String> mapAppSettings = UtilityMethods.APP_SETTINGS();
            Map<String, String> mapObjects = UtilityMethods.OBJECT_MAP();
            Map<String, String> mapObjectLabels = UtilityMethods.OBJECT_LABELMAP();
            Map<Integer, String> mapRESTStatuses = UtilityMethods.STATUS_RESTSERVICE();
            Set<String> setRESTActions = UtilityMethods.ACTIONS_RESTSERVICE();

            Id idRecordType = UtilityMethods.RECORDTYPE_ID('Account', 'Eurofins Client');

            UtilityMethods.LOG_MESSAGE('Test Method', 'Test!');

            Contact conSoundex = new Contact(FirstName='first', Lastname='last');
            insert conSoundex;

            List<String> lstObjectFields = UtilityMethods.fieldsInObject('Account');

            String strQuery = UtilityMethods.getCreatableFieldsSOQL('Contact', 'Lastname = \'last\'');

            UtilityMethods.convertNumberToWord('0123456789');
            UtilityMethods.convertNumberToWord('bad');

            // getValuesforPicklist
            List<String> lstPicklistVals = UtilityMethods.getValuesForPicklist('Lead', 'Status');

            // determineZipZone
            //List<Account> lstAccountsZip = new List<Account>();
            //lstAccountsZip.add(new Account(Name='Test Acct',BillingPostalCode='12345'));
            //insert lstAccountsZip;
            //UtilityMethods.determineZipZone(lstAccountsZip, 'BillingPostalCode','Description');

        test.stopTest();

    }

    @isTest static void testUtilityGlobalMethods() {

        test.startTest();

        Task tskSource = new Task(Subject='Test Task');
        insert tskSource;

        sObject sObjTarget = UtilityGlobalMethods.cloneObject('Subject', tskSource.Id);

        System.Debug(sObjTarget);

        System.Assert(string.valueOf(sObjTarget.get('Subject')).contains('Clone'), 'The Clone did not rename properly!');

        test.stopTest();

    }

    @isTest static void testUtilityMethods2() {
        UtilityMethods.calculateHaversineDistance(1.0, 1.0, 1.0, 1.0);
       
        UtilityMethods.fieldLabelsForNames('Contact');

        UtilityMethods.wordToNumber(0, 'USD');
        UtilityMethods.wordToNumber(2, 'USD');
        UtilityMethods.wordToNumber(30, 'USD');
        UtilityMethods.wordToNumber(400, 'USD');
        UtilityMethods.wordToNumber(5000, 'USD');
        UtilityMethods.wordToNumber(6000000, 'USD');
        UtilityMethods.wordToNumber(700000000, 'USD');
       
        //UtilityMethods um = new UtilityMethods();
        //um.userResourcePools();
       
        UtilityMethods.checkForNullNumber(null);
        UtilityMethods.checkForNull(null);
       
        Set<String> testSet = new Set<String>();
        testSet.add('hello');
        testSet.add('world');
        UtilityMethods.stringSetToCSV(testSet, true);
       
        UtilityMethods.findObjectNameFromRecordIdPrefix('001');
       
        UtilityMethods.USER_PREFERENCES();
        UtilityMethods.convertLongZipToShort('2345678');
       
        //UtilityMethods.hClsLatLongMatrix um1 = new UtilityMethods.hClsLatLongMatrix();
        //um1.hClsLatLongMatrix('Test', '12345', 5.0);
        UtilityMethods.english_number(15);
        UtilityMethods.english_number(156);
        UtilityMethods.english_number(100/32);
       
        String tmp = UtilityMethods.encodeString('hello');
        UtilityMethods.decodeString(tmp);
       
        UtilityMethods.hClsSessionQuotaCounts um2 = new UtilityMethods.hClsSessionQuotaCounts();
        UtilityMethods.hClsValtiraCheckGenerator um3 = new UtilityMethods.hClsValtiraCheckGenerator();

    }
    
}