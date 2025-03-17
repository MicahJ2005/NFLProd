public with sharing class ProfileCompare_FLSController {

public String profile1 {get; set;}
public String profile2 {get; set;}
public String objName { get; set;}

public Boolean showResults {get; set;}
public Boolean showError {get; set;}

public Map<String, String> objReasonMap {get; set;}
public String profileName1 {get; set;}
public String profileName2 {get; set;}

    public ProfileCompare_FLSController() {
        //Set some defaults for testing
        //profile1 = '00e0d0000017apA';
        //profile2 = '00e0d0000017apU';
        showResults = false;
        showError = false;
    }

    public PageReference doCompare() {
        System.debug('DC: profile1: ' + profile1);
        System.debug('DC: profile2: ' + profile2);

        if(profile1 != '' && profile2 != '') {
            try {
                //Get the profile IDs and Names
                Map<Id, String> profileMap = new Map<Id, String>();
                for(Profile p : [SELECT Id, Name FROM Profile WHERE Id = :profile1 OR Id = :profile2]) {
                    profileMap.put(p.Id, p.Name);
                }
                profileName1 = profileMap.get(profile1);
                profileName2 = profileMap.get(profile2);

                //Get the permission set Ids
                Map<Id, Id> profileToPermMap = new Map<Id, String>();
                Map<Id, Id> permToProfileMap = new Map<Id, String>();
                for(PermissionSet ps : [SELECT Id, ProfileId FROM PermissionSet WHERE ProfileId IN :profileMap.keySet()]) {
                    profileToPermMap.put(ps.ProfileId, ps.Id);
                    permToProfileMap.put(ps.Id, ps.ProfileId);
                }

                Map<Id, Map<String, String>> profileToObjMap = new Map<Id, Map<String, String>>();
                List<FieldPermissions> fpList = new List<FieldPermissions>();
                if(objName != '') {
                    fpList = new List<FieldPermissions>([SELECT Id, Field, ParentId, PermissionsEdit, PermissionsRead, SobjectType FROM FieldPermissions WHERE ParentId IN :permToProfileMap.keySet() AND SobjectType = :objName]);
                } else {
                    fpList = new List<FieldPermissions>([SELECT Id, Field, ParentId, PermissionsEdit, PermissionsRead, SobjectType FROM FieldPermissions WHERE ParentId IN :permToProfileMap.keySet()]);
                }



                for(FieldPermissions fp : fpList) {
                    //Object - Field - READ - EDIT
                    String objField = fp.SobjectType + '-' + fp.Field;
                    String perms = fp.PermissionsRead + '-' + fp.PermissionsEdit;
                    String profileId = permToProfileMap.get(fp.ParentId);
                    Map<String, String> tmpMap = profileToObjMap.get(profileId);
                    if(tmpMap == null) {
                        tmpMap = new Map<String, String>();
                    }
                    tmpMap.put(objField, perms);
                    profileToObjMap.put(profileId, tmpMap);
                }

                Map<String, String> profile1Map = profileToObjMap.get(profile1);
                Map<String, String> profile2Map = profileToObjMap.get(profile2);

                objReasonMap = new Map<String, String>();
                //First - what things exist in LIST 1 - but don't have a match in LIST 2
                for(String objField1 : profile1Map.keySet()) {
                    //Does this objField exist in profile2Map>
                    String perms1 = profile1Map.get(objField1);
                    String perms2 = profile2Map.get(objField1);

                    if(perms2 == null) {
                        objReasonMap.put(objField1, 'PROFILE 1 ONLY');
                    } else {
                        if(perms1 != perms2) {
                            objReasonMap.put(objField1, 'PERM1: ' + perms1 + ' ; PERM2: ' + perms2);
                        }
                    }
                }

                for(String objField2 : profile2Map.keySet()) {
                    //Does this objField exist in profile1Map>
                    String perms1 = profile1Map.get(objField2);
                    String perms2 = profile2Map.get(objField2);

                    if(perms1 == null) {
                        objReasonMap.put(objField2, 'PROFILE 2 ONLY');
                    } 
                }

                showResults = true;

            } catch(Exception e) {
                showError = true;
            }
        } else {
            showError = true;
        }

        return null;
    }
}