@isTest
private class ProfileCompare_FLSControllerTest {
    static testMethod void myUnitTest() {
        List<Profile> profileList = new List<Profile>([SELECT Id, Name FROM Profile LIMIT 2]);

        ProfileCompare_FLSController cntrlr = new ProfileCompare_FLSController();
        cntrlr.profile1 = profileList[0].Id;
        cntrlr.profile2 = profileList[1].Id;
        cntrlr.objName = 'Account';
        cntrlr.doCompare();

    }

}