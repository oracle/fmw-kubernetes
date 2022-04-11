/*
 *  Copyright (c) 2021, Oracle and/or its affiliates.
 *  Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 *
 * This is an example of a Java script to create Users for OIRI
 *
 */
import static oracle.iam.identity.rolemgmt.api.RoleManagerConstants.ROLE_DESCRIPTION;
import static oracle.iam.identity.rolemgmt.api.RoleManagerConstants.ROLE_KEY;
import static oracle.iam.identity.rolemgmt.api.RoleManagerConstants.ROLE_NAME;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Hashtable;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.Iterator;

import oracle.iam.api.OIMService;
import oracle.iam.exception.OIMServiceException;
import oracle.iam.identity.rolemgmt.api.RoleManager;
import oracle.iam.identity.rolemgmt.vo.Role;
import oracle.iam.identity.rolemgmt.vo.RoleManagerResult;
import oracle.iam.identity.usermgmt.api.UserManager;
import oracle.iam.identity.usermgmt.api.UserManagerConstants;
import oracle.iam.identity.usermgmt.vo.User;
import oracle.iam.identity.usermgmt.vo.UserManagerResult;
import oracle.iam.identity.exception.OrganizationManagerException;
import oracle.iam.identity.orgmgmt.api.OrganizationManager;
import oracle.iam.identity.orgmgmt.vo.Organization;
import oracle.iam.platform.OIMClient;
import oracle.iam.platform.authopss.vo.AdminRole;
import oracle.iam.platform.authopss.vo.AdminRoleMembership;
import oracle.iam.platformservice.api.AdminRoleService;
import java.sql.SQLException;

public class createAdminUser {
    private static OIMClient oimClient = null;
    
    public static Map<String, String> createUserInOIM( UserManager usrMgr, String newUser, String newUserPwd) throws Exception {
        return createUserWithManagerInOIM(null, usrMgr, newUser,newUserPwd);
    }

    // Create a User in OIM
    //
    public static Map<String, String> createUserWithManagerInOIM(
            String managerKey, UserManager usrMgr, String newUser, String newUserPwd) throws Exception {

        HashMap<String, Object> newUserData = new HashMap<String, Object>();

        newUserData.put("User Login", newUser);
        newUserData.put("First Name", newUser);
        newUserData.put("Last Name", newUser);
        newUserData.put("Middle Name", newUser);
        newUserData.put("usr_password", newUserPwd);
        newUserData.put("act_key", new Long(1));
        newUserData.put("Xellerate Type", "End-User");
        newUserData.put("Role", "Full-Time");
        newUserData.put("Common Name", newUser);

        if (managerKey != null && managerKey.length() > 0) {
            try {
                long mgr_key = Long.valueOf(managerKey);
                newUserData.put("usr_manager_key", mgr_key);
            } catch(NumberFormatException nfe) {
                newUserData.put("usr_manager_key", managerKey);
            }
        }

        UserManagerResult result = usrMgr.create(new User(null,
                newUserData));
        Map<String, String> userInfo = new HashMap<String, String>();
        userInfo.put("user login", newUser);
        userInfo.put("user entity key", result.getEntityId());
        System.out.println("Created User:"+newUser);
        return userInfo;
    }

    // Create a Role in OIM
    //
    public static String createRoleInOIM( String roleName) throws Exception { 

        RoleManager roleMgr = oimClient.getService(RoleManager.class);
        RoleManagerResult roleResult = null;

        HashMap<String, Object> newRoleData = new HashMap<String, Object>();

        newRoleData.put("Role Name", roleName);
        newRoleData.put("Role Display Name", roleName);
        newRoleData.put("Role Description", "OIRI Engineer Role");

        Role role = new Role(newRoleData);
        roleResult = roleMgr.create(role);

        String roleId = roleResult.getEntityId();

        System.out.println("Created Role: Id: "+roleId+" Name: "+roleName);
        return roleId;
    }


    // Assign an OIM Admin Role to a User
    //
    public static void assignAdminRoleToUser(String adminRoleName, String userName, String orgName) throws Exception {

        AdminRoleService adminRoleSvc = oimClient.getService(AdminRoleService.class);

        AdminRole adminRole = getAdminRoleByName(adminRoleName);
        if(null== adminRole){
            System.out.println("Admin role <"+adminRoleName+"> does not exist");
            return;
         }

        String orgKey = getOrganisationID(orgName);
        if(null== orgKey){
            System.out.println("Organization <"+orgName+"> does not exist");
            return;
         }
         
        String usrKey = getUserKeyByUserLogin(userName);
        if(null== usrKey){
            System.out.println("User <"+userName+"> does not exist");
            return;
         }

         AdminRoleMembership membership = new AdminRoleMembership();
         membership.setAdminRole(adminRole);
         membership.setUserId(usrKey);
         membership.setScopeId(orgKey);
         membership.setHierarchicalScope(true);

         try {
                adminRoleSvc.addAdminRoleMembership(membership);
                System.out.println(adminRole+" Role Successfully Assigned to User");
             } catch (Exception e) {
                   e.printStackTrace();
               }
     }
    
    // Get the internal ID of an Admin Role using its name
    //
    private static AdminRole getAdminRoleByName(String adminRoleName){

        AdminRoleService adminRoleSvc = oimClient.getService(AdminRoleService.class);

        try {
                AdminRole adminRole = adminRoleSvc.getAdminRole(adminRoleName);
                if (adminRole.getRoleName().equals(adminRoleName)) {
                    return adminRole;
                }
              } catch (Exception e) {
                   e.printStackTrace();
              }
        return null;
     }

     // Get the Internal ID of an Organisation using its name
     //
     private static String getOrganisationID(String orgName) {

        OrganizationManager orgManager = oimClient.getService(OrganizationManager.class);
        Organization org;
        try {
              org = orgManager.getDetails(orgName,null,true);
              return org.getEntityId();
            } catch (OrganizationManagerException e) {
              e.printStackTrace();
              return null;
            }
      }


    // Get the Internal ID of a User using its login name
    //
    public static String getUserKeyByUserLogin(String userLogin) {
     
       HashSet<String> attrsToFetch = new HashSet<String>();
       attrsToFetch.add(UserManagerConstants.AttributeName.USER_KEY.getId());

       try {
             UserManager userService= oimClient.getService(UserManager.class);
             
             User user = userService.getDetails(userLogin, attrsToFetch,true);
             return user.getEntityId();
           } catch(Exception e){
             return null;
           }
    }

    // Get the internal ID of a Role using its name
    //
    public static String getRoleByName(String roleName ) {
        
        RoleManager roleMgr = oimClient.getService(RoleManager.class);

        HashMap<String, Object> roleAttributes = new HashMap<String, Object>();
        roleAttributes.put("Role Name", roleName);

        try {
              Role roleObject = new Role(roleAttributes);
              Role engRole = roleMgr.getDetails("Role Name",roleName,null);
              return engRole.getEntityId();
           } catch(Exception e){
             return null;
           }
    }

    // Assign a Role to a User using the Name of the Role and the Name of the User
    //
    public static void assignRole(String engRoleName, String engUserName ) {


        RoleManager roleMgr = oimClient.getService(RoleManager.class);

        String engRoleId = getRoleByName(engRoleName);
        String engUsrKey = getUserKeyByUserLogin(engUserName);

        try {
              Set<String> userKeys = new HashSet<String>();
              userKeys.add(engUsrKey);
              roleMgr.grantRole(engRoleId,userKeys);
           } catch(Exception e){
              e.printStackTrace();
           }
           System.out.println("Successfully assigned User "+engUserName+" to Role "+engUserName);

    }


    // Main Program
    //
    static public void main(String[] args) throws Exception {

                String serverURL = args[0];
                String userName = args[1];
                String passwd = args[2];
                String newUser = args[3];
                String newUserPwd = args[4];
                String engUser = args[5];
                String engUserPwd = args[6];
                String engRole = args[7];

        // Connect to OIM 
        try {
            String ctxFactory = "weblogic.jndi.WLInitialContextFactory";


            System.out.println("Server URL is : " + serverURL);
            System.out.println("Context Factory is : " + ctxFactory);
            Hashtable env = new Hashtable();
            env.put(OIMClient.JAVA_NAMING_PROVIDER_URL, serverURL);
            env.put(OIMClient.JAVA_NAMING_FACTORY_INITIAL, "weblogic.jndi.WLInitialContextFactory");
            oimClient = new OIMClient(env);
            oimClient.login(userName, passwd);
        } catch (Exception e) {
            e.printStackTrace();
        }
        UserManager usrMgr = null;
        usrMgr = (UserManager) oimClient.getService(UserManager.class);

        // Create the Service User if it does not exist
        //
        String usrKey = getUserKeyByUserLogin(newUser);
        if(null== usrKey){
            System.out.println("User <"+newUser+"> does not exist - Creating");
            Map<String, String> newUserInfo = createUserInOIM(usrMgr,newUser,newUserPwd);
         } else {
            System.out.println("User <"+newUser+"> Id <"+usrKey+"> Exists");
         }

        // Assing System Admin Roles to Service User 
        assignAdminRoleToUser("OrclOIMUserViewer",newUser,"Top");
        assignAdminRoleToUser("OrclOIMRoleAdministrator",newUser,"Top");
        assignAdminRoleToUser("OrclOIMAccessPolicyAdministrator",newUser,"Top");
        
        // Create Engineering User if it doesnt exist
        String engUsrKey = getUserKeyByUserLogin(engUser);
        if(null== engUsrKey){
            System.out.println("User <"+engUser+"> does not exist - Creating");
            Map<String, String> newUserInfo = createUserInOIM(usrMgr,engUser,engUserPwd);
         } else {
            System.out.println("User <"+engUser+"> Id <"+engUsrKey+"> Exists");
         }

        // Create Engineering Role if it doesnt exist
        String engRoleId = getRoleByName(engRole);
        if(null== engRoleId){
            System.out.println("Role <"+engRole+"> does not exist - Creating");
            String roleId = createRoleInOIM(engRole);
         } else {
            System.out.println("Role <"+engRole+"> Exists");
         }

        
        // Assing the Engineering Role to the Engineering User in OIM 
        assignRole(engRole, engUser);

    }

}

