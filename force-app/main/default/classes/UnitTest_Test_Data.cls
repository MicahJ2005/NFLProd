@isTest
public class UnitTest_Test_Data {

 //Returns a valid mock User
  public static User buildTestUser(Integer i, String profilename) {
    User newuser = new User();
    newuser.LastName = profilename + i;
    newuser.Alias = 'user' + i;
    newuser.Email = 'marc@fpitestmethods.com';
    newuser.Username = 'test_' + i + '@fpi.com';
    newuser.EmployeeNumber = '1234567890';
    newuser.CommunityNickname = 'test_' + i + '@FPI.com';
    newuser.ProfileId = [SELECT id FROM Profile WHERE name = :profilename].id;
    newuser.TimeZoneSidKey = 'America/Los_Angeles';
    newuser.LocaleSidKey = 'en_US';
    newuser.EmailEncodingKey = 'UTF-8';
    newuser.LanguageLocaleKey = 'en_US';
    newuser.isActive = true;
    return newuser;
  }
//Returns a valid Account
  public static Account buildTestAccount(String RecordTypeName, Id OwnerId){

      DescribeFieldResult describe = Account.Brand__c.getDescribe();
      List<PicklistEntry> availableValues = describe.getPicklistValues();
      String strBrandValue = availableValues[0].getValue();

      String randNo = String.valueOf(Crypto.getRandomInteger());

      Account newaccount = new Account ();
      newaccount.Name = 'Completely Random Test Account ' + randNo;
      newaccount.Type = 'Customer';
      //newaccount.RecordTypeId = [SELECT Id FROM RecordType WHERE name = :RecordTypeName AND SobjectType = 'Account'].id;
      newaccount.RecordTypeId = UtilityMethods.RECORDTYPE_ID('Account', RecordTypeName);
      newaccount.OwnerId = OwnerId;
      newaccount.Phone = '952-777-FAKE';
      newaccount.BillingStreet = randNo + '7640 FPI Way';
      newaccount.BillingCity = 'Non-Existent City';
      newaccount.BillingState = 'Minnesota';
      newaccount.BillingPostalCode = '55344';
      newaccount.BillingCountry = 'United States';
      newaccount.Industry = 'Other';
      newaccount.Brand__c = strBrandValue;
      newaccount.Verification__c = 'Verified';
      return newaccount;
  }
//Returns a valid Lead
  public static Lead buildFPILead (ID OwnerId, string Email, string RecordTypeName){
      Lead l = new Lead();
      	l.lastname = 'Lastname';
        l.firstname = 'FirstName';
        l.title = 'Pres';
        l.company = 'Company';
        l.street = '123 Main';
        l.city = 'Eden Prairie';
        l.state = 'Minnesota';
        l.PostalCode = '12345';
        l.Country = 'United States';
        //l.RecordTypeId = [SELECT Id FROM RecordType WHERE name = :RecordTypeName AND SobjectType = 'Lead'].id;
        l.RecordTypeId = UtilityMethods.RECORDTYPE_ID('Lead', RecordTypeName);
        l.Phone = '952-666-4444';
        l.Email = Email;
        l.Industry = 'Manufacturing';
        l.LeadSource = 'Direct_Mail';
      return l;
    }
//Returns a valid Opportunity
  public static Opportunity BuildOpportunity(Id TestAccount, String RecordTypeName, String Stage){
    Opportunity newop = new Opportunity ();
    	newop.AccountId = TestAccount;
      	//newop.RecordTypeId = [SELECT Id FROM RecordType WHERE name = :RecordTypeName AND SobjectType = 'Opportunity'].id;
        newop.RecordTypeId = UtilityMethods.RECORDTYPE_ID('Opportunity', RecordTypeName);
      	newop.Name = 'Oppty Test 1';
      	newop.CloseDate = date.today() + 10;
      	newop.Amount = 100;
      	newop.Product_Category__c = 'Cereal';
      	newop.StageName = Stage;
      return newop;
  }
//Returns a valid Contact
  public static Contact BuildContact (Integer i, ID testUserId, ID AccountID, String RecordTypeName){
    Contact newContact = new Contact();
      newContact.AccountId = AccountID;
      newContact.LastName = 'Smith ' + i;
      newContact.FirstName = 'John ' + i;
      newContact.Birthdate = System.Today().addYears(-30);
      newContact.OwnerId = testUserId;
      //newContact.RecordTypeId = [SELECT Id FROM RecordType WHERE name = :RecordTypeName AND SobjectType = 'Contact'].id;
      newContact.RecordTypeId = UtilityMethods.RECORDTYPE_ID('Contact', RecordTypeName);
      newContact.Brand__c = 'Plymouth';
      return newContact;
    }
//Returns a valid Attribute Master
  /**public static Attribute_Master__c BuildAttributeMaster(boolean Active, boolean IsPublic ){
  	Attribute_Master__c newAM = new Attribute_Master__c();
  		newAM.Name = 'Test';
  		newAM.Category__c = 'Account';
  		newAM.IsActive__c = Active;
  		newAM.IsPublic__c = IsPublic;
  		newAM.KeyFieldName__c = 'Test123';
  		newAM.NameSoundexKey__c = 'T123';
  		newAM.OptionValues__c = 'Testing123 Testing';
  		newAM.Refresh_Interval__c = 10;
  		newAM.Scope__c = 'Single-Use';
  		newAM.Type__c = 'Text';
  		return newAM;
  }*/
  
//Returns a valid Master_Test__c
	public static Master_Test__c BuildMasterTest(){
		Master_Test__c newMT = new Master_Test__c();
		return newMT;
  }
  
  public static void buildMQ_Session_SQs(Id masterTestId, Id testingLocationId) {
        Quota__c testMQ1 = new Quota__c();
        testMQ1.Quota_Summary__c = 'conditionsCaucasian';
        testMQ1.Minimum_Respondents__c = 1;
        testMQ1.Maximum_Respondents__c = 100;
        testMQ1.Related_Test__c = masterTestId;
        testMQ1.IsTrackingOnly__c = FALSE;
        testMQ1.IsScheduleEnabled__c = TRUE;
        //insert(testMQ1);
        
        Quota__c testMQ2 = new Quota__c();
        testMQ2.Quota_Summary__c = 'conditionsPOInterested';
        testMQ2.Minimum_Respondents__c = 1;
        testMQ2.Maximum_Respondents__c = 100;
        testMQ2.Related_Test__c = masterTestId;
        testMQ2.IsTrackingOnly__c = TRUE;
        testMQ2.IsScheduleEnabled__c = TRUE;
        //insert(testMQ2);

        insert new List<Quota__c>{testMQ1, testMQ2};

        Session__c testSession1 = new Session__c();
        testSession1.Test_Type__c = 'CLT - Central Location Test';
        testSession1.Check_Amount__c = 35;
        testSession1.Related_Test__c = masterTestId;
        testSession1.Session_Start__c = Datetime.newInstance(2020,1,1,1,2,3);
        testSession1.Session_End__c = Datetime.newInstance(2020,1,1,2,2,3);
        testSession1.Testing_Location__c = testingLocationId;
        insert testSession1;
        
        Session_Quota__c testSQ1_1 = new Session_Quota__c();
        testSQ1_1.Master_Quota__c = testMQ1.Id;
        testSQ1_1.Related_Session__c = testSession1.Id;
        //insert(testSQ1_1);

        Session_Quota__c testSQ1_2 = new Session_Quota__c();
        testSQ1_2.Master_Quota__c = testMQ2.Id;
        testSQ1_2.Related_Session__c = testSession1.Id;
        //insert(testSQ1_2);

        Session__c testSession2 = new Session__c();
        testSession2.Test_Type__c = 'CLT - Central Location Test';
        testSession2.Check_Amount__c = 35;
        testSession2.Related_Test__c = masterTestId;
        testSession2.Session_Start__c = Datetime.newInstance(2020,1,1,1,2,3);
        testSession2.Session_End__c = Datetime.newInstance(2020,1,1,2,2,3);
        testSession2.Linked_Session__c = testSession1.Id;
        testSession2.Testing_Location__c = testingLocationId;
        insert testSession2;
        
        Session_Quota__c testSQ2_1 = new Session_Quota__c();
        testSQ2_1.Master_Quota__c = testMQ1.Id;
        testSQ2_1.Related_Session__c = testSession2.Id;
        //insert(testSQ2_1);

        Session_Quota__c testSQ2_2 = new Session_Quota__c();
        testSQ2_2.Master_Quota__c = testMQ2.Id;
        testSQ2_2.Related_Session__c = testSession2.Id;
        //insert(testSQ2_2);

        insert new List<Session_Quota__c>{testSQ1_1, testSQ1_2, testSQ2_1, testSQ2_2};
  }


//Returns a valid Test_Respondent__c
	public static Test_Respondent__c BuildTestRespondent(ID ContactID, ID MasterTestID){
		Test_Respondent__c newTR = new Test_Respondent__c();
			newTR.Respondent__c = ContactID;
			newTR.Master_Test__c = MasterTestID;
		return newTR;
  }
    
//Returns a valid Test_Respondent_Quota__c
	public static Test_Respondent_Quota__c BuildTRQ(ID RespondentID, ID SessionQuotaID){
		    Test_Respondent_Quota__c trqQuant = new Test_Respondent_Quota__c();
            trqQuant.Test_Respondent__c = RespondentID;
            trqQuant.Session_Quota__c = SessionQuotaID;
		return trqQuant;
  }
    
//Returns a valid Profile Record
/** 
  public static Profile__c BuildProfile (boolean Available, Id ProfileTemplate, String RelatedID, boolean IsTemplate){
  	Profile__c newP = new Profile__c ();
  		newP.Name = 'TestProfile';
  		newP.IsAvailable__c = Available;
  		newP.Display_Array__c = 'Long Text Profile';
  		newP.Profile_Template__c = ProfileTemplate;
  		newP.RelatedId__c = RelatedID;
  		newP.IsTemplate__c = IsTemplate;
  	return newP;
  }
*/
//Returns a valid Profile Attributes
/**   public static Profile_Attributes__c BuildProfileAttributes (Id AttributeID, Id ProfileID, boolean TemplateItem){
  	Profile_Attributes__c newPA = new Profile_Attributes__c ();
  		newPA.Attribute_Master__c = AttributeID;
  		newPA.Category_Order__c = 10;
  		newPA.IsTemplateItem__c = TemplateItem;
  		newPA.Profile__c = ProfileID;
  		newPA.SubCategory__c = 'TestSubcategory';
  		newPA.Value__c = 'TestValue';
  	return newPA;
  }*/
//Returns a valid Project Details
/**   public static Project_Detail__c BuildProjectDetail (Id DesignOverviewID){
  	Project_Detail__c newPD = new Project_Detail__c ();
  		newPD.Name = 'ProjectDetailName';
  		newPD.Notes__c = 'Notes section Test';
  		newPD.Parent_Project_Detail__c = DesignOverviewID;
  	return newPD;
  }*/
//Returns a valid PD_Junction
/**   public static PD_Junction__c BuildPDJunction (Id ProjectDetailID, string RelatedID){
  	PD_Junction__c newPDJ = new PD_Junction__c ();
  		newPDJ.Project_Detail__c = ProjectDetailID;
  		newPDJ.RelatedId__c = RelatedID;
  	return newPDJ;
  } */
//Returns a valid Quotes
  public static Quote BuildQuote (Id OppID, String QuoteName){
  	Quote newQ = new Quote ();
  		newQ.OpportunityId = OppID;
  		newQ.Name = QuoteName;
  		newQ.Status = 'Draft';
  	return newQ;
  }

//Returns a Custom Setting for FPI_APEXSettings__c
  public static FPI_APEXSettings__c BuildFPI_ApexSetting (boolean Active, string ApexName){
  	FPI_APEXSettings__c newFPIas = new FPI_APEXSettings__c ();
  		newFPIas.IsActive__c  = Active;
  		newFPIas.Name = ApexName;
  	return newFPIas;
  }
//Returns a Custom Setting for FPI_AppSettings__c enter in ID only
  public static FPI_AppSettings__c BuildFPI_AppSettings (string SettingName, string value){
  	FPI_AppSettings__c newFPIsetting = new FPI_AppSettings__c ();
  		newFPIsetting.Value__c = value;
  		newFPIsetting.Name = SettingName;
  	return newFPIsetting;
  }
  public static FPI_AppSettings__c BuildFPI_AppSettings (string SettingName, DateTime value){
  	FPI_AppSettings__c newFPIsetting = new FPI_AppSettings__c ();
  		newFPIsetting.Value_DateTime__c = value;
  		newFPIsetting.Name = SettingName;
  	return newFPIsetting;
  }
//Returns a Custom Setting for FPI_AppSettings__c with Record Type lookup
  public static FPI_AppSettings__c BuildFPI_AppSettings_RecordTypeLookup (string SettingName, string RecordTypeName, string SobjectName){
  	FPI_AppSettings__c newFPIsetting = new FPI_AppSettings__c ();
  		//newFPIsetting.Value__c = [SELECT Id FROM RecordType WHERE name = :RecordTypeName AND SobjectType = :SobjectName].id;
      newFPIsetting.Value__c = UtilityMethods.RECORDTYPE_ID(SobjectName, RecordTypeName);
  		newFPIsetting.Name = SettingName;
  	return newFPIsetting;
  }
//Returns a Custom Setting for FPI_AppSettings__c enter in ID only
  public static Zip_Code_Zones__c BuildZipZoneSetting (string value, string SettingName){
    Zip_Code_Zones__c newZipZonesetting = new Zip_Code_Zones__c ();
      newZipZonesetting.Zone__c = value;
      newZipZonesetting.Name = SettingName;
      newZipZonesetting.Lat__c = 44.7827;
      newZipZonesetting.Long__c = -93.9133;
    return newZipZonesetting;
  }
//Returns a Custom Setting for HostToolEmailSettings__c
  public static HostToolEmailSettings__c BuildHostEmailSetting (String csName){
    HostToolEmailSettings__c newHostEmail = new HostToolEmailSettings__c();
      newHostEmail.Name = csName;
      newHostEmail.Email_Template_Id__c = '00XR0000000IhDF';
      newHostEmail.MessageToDisplay__c = 'Test Message';
      newHostEmail.OrgWideEmailId__c = '0D2U0000000Kzyf';
      newHostEmail.To_Email_Addresses__c = 'test@test.com;test1@test1.com';
    return newHostEmail;
  }
//Returns a Custom Setting for HostToolColorCoding__c
  public static List<HostToolColorCoding__c> BuildHostColor (){
    List<HostToolColorCoding__c> lstHTColor = new List<HostToolColorCoding__c>();
    List<String> lstStr = new List<String>();
    for(String str : UtilityMethods.getValuesForPicklist('Test_Respondent__c', 'Tested_Status__c')) {
        HostToolColorCoding__c htcc = new HostToolColorCoding__c();
        htcc.Name = str;
        htcc.HexColor__c = '#32CD32';
        lstHTColor.add(htcc);
    }
    return lstHTColor;
  }

  public static void commitZipZoneData() {

    List<Zip_Code_Zones__c> lstLatLong = new List<Zip_Code_Zones__c>();
    lstLatLong.add(new Zip_Code_Zones__c(Name='55321',Zone__c='CLOSE',Lat__c=44.6683,Long__c=-93.7870));
    lstLatLong.add(new Zip_Code_Zones__c(Name='55322',Zone__c='Southeast',Lat__c=44.7683,Long__c=-93.7870));
    lstLatLong.add(new Zip_Code_Zones__c(Name='55387',Zone__c='Southeast',Lat__c=44.8587,Long__c=-93.7796));
    lstLatLong.add(new Zip_Code_Zones__c(Name='55555',Zone__c='Southeast',Lat__c=44.7827,Long__c=-93.9133));    
    lstLatLong.add(new Zip_Code_Zones__c(Name='55344',Zone__c='Southeast',Lat__c=44.8655,Long__c=-93.4304));
    lstLatLong.add(new Zip_Code_Zones__c(Name='55318',Zone__c='Southeast',Lat__c=44.8087,Long__c=-93.6418));
    lstLatLong.add(new Zip_Code_Zones__c(Name='55436',Zone__c='Southeast',Lat__c=44.9043,Long__c=-93.3750));
    lstLatLong.add(new Zip_Code_Zones__c(Name='55420',Zone__c='Southeast',Lat__c=44.8362,Long__c=-93.2776));
    insert lstLatLong;

    Id rtTestingLocation = UtilityMethods.RECORDTYPE_ID('Account','Local Testing Location');
    List<Account> lstTestingCenters = new List<Account>();
    lstTestingCenters.add(new Account(Name='test1',Site_Code__c='a',BillingPostalCode='55321',RecordTypeId=rtTestingLocation,Include_With_Respondent_Zone__c=true));
    lstTestingCenters.add(new Account(Name='test1',Site_Code__c='1',BillingPostalCode='55555',RecordTypeId=rtTestingLocation,Include_With_Respondent_Zone__c=true));
    lstTestingCenters.add(new Account(Name='test1',Site_Code__c='2',BillingPostalCode='55322',RecordTypeId=rtTestingLocation,Include_With_Respondent_Zone__c=true));
    lstTestingCenters.add(new Account(Name='test2',Site_Code__c='3',BillingPostalCode='55387',RecordTypeId=rtTestingLocation,Include_With_Respondent_Zone__c=true));
    lstTestingCenters.add(new Account(Name='test3',Site_Code__c='4',BillingPostalCode='55344',RecordTypeId=rtTestingLocation,Include_With_Respondent_Zone__c=true));
    lstTestingCenters.add(new Account(Name='test4',Site_Code__c='5',BillingPostalCode='55318',RecordTypeId=rtTestingLocation,Include_With_Respondent_Zone__c=true));
    lstTestingCenters.add(new Account(Name='test5',Site_Code__c='6',BillingPostalCode='55436',RecordTypeId=rtTestingLocation,Include_With_Respondent_Zone__c=true));
    lstTestingCenters.add(new Account(Name='test6',Site_Code__c='7',BillingPostalCode='55420',RecordTypeId=rtTestingLocation,Include_With_Respondent_Zone__c=true));
    insert lstTestingCenters;

  }

  public static void commitFPIApexSettings(Boolean createRespondentAccount) {
    if(createRespondentAccount == true) {
      Account testAccount = BuildTestAccount('Respondent Master Account', UserInfo.getUserId());
      insert testAccount;
      
      FPI_AppSettings__c testAppSetting1 = BuildFPI_AppSettings('ID_RespondentAccount', testAccount.Id);
      insert testAppSetting1;
    }
    commitFPIApexSettings();
  }

  public static void commitFPIApexSettings() {

    List<FPI_APEXSettings__c> lstApexSettings = new List<FPI_APEXSettings__c>();
    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'assignToRespondentAccount'));
    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'AttributeMasterSoundexKey'));
    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'computeProfileName'));
    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'contactSoundexKey'));
    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'leadSoundexKey'));
    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'moveProfileOnLeadConvert'));
    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'updateRespondentCoreAttributes'));
    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'mapPDJunctionToAvataList'));
    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'updateZipCodeContactWork'));
    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'updateZipCodeHousehold'));
    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'updateZipCodeAccount'));
    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'sessionQuotaCompute'));
    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'ContactRollups'));
    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'Contact-Respondent-Reporting'));
    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(false, 'Contact-Respondent-ReportingDates'));
    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'BatchRecruitingRollups'));

    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'enableContactTrigger'));
    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'enableHouseholdContactTrigger'));
    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'enableHouseholdTrigger'));
    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'enablePushNotificationTrigger'));
    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'enableSPEmailTrigger'));
    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'enableTestRespondentTrigger'));
    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'enableTRQTrigger'));

    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'enableEngagementProfileTrigger'));
    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'enableEngagementTransactionTrigger'));

    lstApexSettings.add(UnitTest_Test_data.BuildFPI_ApexSetting(true, 'TransmitCheckDataToWFPositivePay'));
    insert lstApexSettings;

    List<FPI_AppSettings__c> lstAppSettings = new List<FPI_AppSettings__c>();
    //NAME - then VALUE
    lstAppSettings.add(UnitTest_Test_data.BuildFPI_AppSettings('MetricBatchSize', '10'));
    lstAppSettings.add(UnitTest_Test_Data.BuildFPI_AppSettings('SNSAccessKey','AMAZON1'));
    lstAppSettings.add(UnitTest_Test_Data.BuildFPI_AppSettings('SNSAccountNumber','AMAZON2'));
    lstAppSettings.add(UnitTest_Test_Data.BuildFPI_AppSettings('SNSHostName','sns.us-east-2.amazonaws.com'));
    lstAppSettings.add(UnitTest_Test_Data.BuildFPI_AppSettings('SNSRegionName','us-east-2'));
    lstAppSettings.add(UnitTest_Test_Data.BuildFPI_AppSettings('SNSSecretKey','AMAZON3'));
    lstAppSettings.add(UnitTest_Test_Data.BuildFPI_AppSettings('SNSTopicRoot','arn:aws:sns:us-east-2'));

    lstAppSettings.add(UnitTest_Test_Data.BuildFPI_AppSettings('Profile_Update_BatchSize','10'));
    lstAppSettings.add(UnitTest_Test_Data.BuildFPI_AppSettings('Profile_TestRespondentTestIds',''));

    lstAppSettings.add(UnitTest_Test_Data.BuildFPI_AppSettings('EngagementBatch_LastProcessDate',DateTime.now().addDays(-2)));
    lstAppSettings.add(UnitTest_Test_Data.BuildFPI_AppSettings('EngagementBatch_StartProcessDate',DateTime.now().addDays(-2)));
    lstAppSettings.add(UnitTest_Test_Data.BuildFPI_AppSettings('Engagement_ReferralAmount','.10'));
    lstAppSettings.add(UnitTest_Test_Data.BuildFPI_AppSettings('Engagement_ProfileSurveyAmount','.10'));

    lstAppSettings.add(UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactBusiness', 'Eurofins Client Contact', 'Contact'));
    lstAppSettings.add(UnitTest_Test_data.BuildFPI_AppSettings_RecordTypeLookup('RT_ContactRespondentAdult', 'Adult-Respondent', 'Contact'));

    lstAppSettings.add(UnitTest_Test_data.BuildFPI_AppSettings('CurrentCheckNumber','1000'));
    lstAppSettings.add(UnitTest_Test_data.BuildFPI_AppSettings('Valtira_PositivePay_Endpoint','https://pdf-api.valtira.com/fill-acro-form/bulk'));
    lstAppSettings.add(UnitTest_Test_data.BuildFPI_AppSettings('Valtira_Endpoint','https://pdf-api.valtira.com/fill-acro-form/bulk'));
    lstAppSettings.add(UnitTest_Test_data.BuildFPI_AppSettings('Valtira_MICRUrl','https://s3.us-east-2.amazonaws.com/fpi-chex/IDAutomationMICR.ttf'));
    lstAppSettings.add(UnitTest_Test_data.BuildFPI_AppSettings('Valtira_S3Bucket','fpi-chex'));
    lstAppSettings.add(UnitTest_Test_data.BuildFPI_AppSettings('Valtira_S3Region','US_EAST_2'));
    lstAppSettings.add(UnitTest_Test_data.BuildFPI_AppSettings('Valtira_Template','CheckTemplatev1-7.pdf'));
    lstAppSettings.add(UnitTest_Test_data.BuildFPI_AppSettings('Valtira_CheckSignature','https://s3.us-east-2.amazonaws.com/fpi-chex/CovanceSig.png'));
    lstAppSettings.add(UnitTest_Test_data.BuildFPI_AppSettings('Valtira_CheckThankYou','https://s3.us-east-2.amazonaws.com/fpi-chex/thank-you-cursive.jpg'));
    lstAppSettings.add(UnitTest_Test_data.BuildFPI_AppSettings('Valtira_APIKey','SRm9c5uVVA630JFh4jXjzan1YEwA7A4P2TIqkSBS'));
    lstAppSettings.add(UnitTest_Test_data.BuildFPI_AppSettings('Valtira_PositivePay_APIKey','https://pdf-api.valtira.com/fill-acro-form/bulk'));
      
    insert lstAppSettings;
    
  }

public static Contact createRespondent() {

  Account testAccount = BuildTestAccount('Respondent Master Account', UserInfo.getUserId());
  insert testAccount;

  Contact testContact = BuildContact(1, UserInfo.getUserId(), testAccount.Id, 'Adult-Respondent');
  insert testContact;

  return testContact;

}

public static Household__c createHouseholdAndHouseholdContact(Id contactId) {
  // Create Households
  Household__c hseSource = new Household__c();
  hseSource.MailingStreet__c = '123 MyStreet Road';
  hseSource.MailingState__c = 'MN';
  //01.28.2021 - Sophia Murphy (Demand Chain) - Added
  hseSource.Head_of_Household__c = contactId;
  insert hseSource;

  Household_Contact__c hcSource = new Household_Contact__c();
  hcSource.Household__c=hseSource.Id;
  hcSource.Contact__c=contactId;
  insert hcSource;

  return hseSource;
}
  
//Returns a Case
public static Case BuildCase(){
	Case newCase = new Case();
		newCase.Status = 'New';
		newCase.Subject = 'Test';
	return newCase;
}  
//Returns and Email Message  
  public static EmailMessage BuildEmailMessage (Id CaseID){
  	EmailMessage newEM = new EmailMessage();
  		newEM.ParentId = CaseID;
  		newEM.Subject = 'test';
  		newEM.TextBody = 'test123';
  	return newEM;
  }
//Return a Task_Queue
public static Task_Queue__c BuildTaskQueue (){
    Task_Queue__c newTQ = new Task_Queue__c();
      newTQ.Name = 'Test';
    return newTQ;
  }
}