/**
 * @description       : Controller class for Login and Registration of Communities
 * @author            : Nitish Pisal(Deloitte-CDC)
 * @group             : Apex
 * Modifications Log
 * Ver   Date         Author                               Modification
 * 1.0   03-11-2022   Nitish Pisal(Deloitte-CDC)           Initial Version
**/

public without sharing class CommunityAuthController {
		private Static String CDC_COMMUNITY_NAME = 'MFATest2';
        private Static String ACCOUNT_NAME = 'CDC Salesforce';
    	private Static String WELCOME_EMAIL = 'Communities: New Member Welcome Email';
        private Static final String PROFILE_NAME = 'CDC Team Community Plus';

        public CommunityAuthController() {

        }

        @AuraEnabled
        public static string doLogin(String username, String password){
             try {
                List<Network> communities = [SELECT Id, Name FROM Network WHERE Name = :CDC_COMMUNITY_NAME];
                String landingURL = Network.getLoginUrl(communities[0].Id).removeEnd('/login');
                ApexPages.PageReference pageRef = Site.login(username, password, landingURL);
                if(pageRef != null)
                    return pageRef.getUrl();
            } catch (Exception e) {
                Throw new AuraHandledException(e.getMessage());
            }
         	return null;
        }


        @AuraEnabled
        public static boolean isEmailExist(String username){
            try {
                List<User> userList = new List<User>();
                userList = [Select Id, Name From User Where Username = :username];
                return !userList.isEmpty();
            } catch (Exception e) {
                Throw new AuraHandledException(e.getMessage());
            }
        }

        @AuraEnabled
        public static String registerUser(String firstName, String lastName, String username, String email,
                                          String password, String hireDate, String birthDay, String birthMonth,
                                          String certURL){


            try {
                DateTime currentTime = System.now();
                Long timeInMili = currentTime.getTime()/1000;
                String uniqueNick = username+timeInMili;

                User u = new User();
                u.firstName = firstName;
                u.lastName = lastName;
                u.Username = username;
                u.Email = email;
                u.CommunityNickname = uniqueNick.length() > 40 ? uniqueNick.substring(0,39) : uniqueNick;
                //u.ProfileId = CDC_Utility.getProfileId(PROFILE_NAME);
                u.Alias = 'sfdc';
                u.LanguageLocaleKey='en_US';
                u.EmailEncodingKey='UTF-8';
                u.LocaleSidKey='en_US';
                u.TimeZoneSidKey='America/Chicago';
                u.IsActive = true;

                List<Account> CommunityAccount = [SELECT ID FROM Account WHERE Name=: ACCOUNT_NAME LIMIT 1];
                String ACCOUNT_ID = !CommunityAccount.isEmpty() ? CommunityAccount[0].Id : '';
                String userId = Site.createExternalUser(u, ACCOUNT_ID, password);

                if (userId != null) {
                    String emailResult = sendWelcomeMail(u, userId);
                    updateContact(userId, birthDay, birthMonth, hireDate, certURL);

                    if (password != null && password.length() > 1) {
                        ApexPages.PageReference pageRef = Site.login(username, password, null);
                        if(pageRef != null) return pageRef.getUrl();
                    }
                    else {
                        ApexPages.PageReference page = System.Page.SiteRegisterConfirm;
                        page.setRedirect(true);
                        return page.getUrl();
                    }
                }
                return null;
            } catch (Exception e) {
                Throw new AuraHandledException(e.getMessage());
            }
        }

        @AuraEnabled
        public static void updateContact(String userId, String birthDay, String birthMonth, String hireDate, String certURL){
            List<sObject> recordToUpdate = new List<sObject>();
            List<User> usr = [SELECT Id FROM User WHERE Id =: userId Limit 1];
            if(!usr.isEmpty()){
                String tempURL= !String.isBlank(certURL) && certURL.contains('http') ? certURL.split('searchString=')[1]: certURL;
                Contact cont = usr[0].Contact;
                recordToUpdate.add(cont);
                update recordToUpdate;
            }
        }

        @AuraEnabled
        public static string sendWelcomeMail(User usr, String userId){
            try {

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                List<EmailTemplate> welcomeTemplate = new List<EmailTemplate>([Select Id from EmailTemplate where name = :WELCOME_EMAIL]);

                mail.setSenderDisplayName('Team CDC');
                mail.setTargetObjectId(userId);
                mail.setTemplateId(welcomeTemplate[0].Id);
                mail.setSaveAsActivity(false);

                Messaging.sendEmail( new List<Messaging.SingleEmailMessage>{mail} );
                return 'success';

            } catch (Exception e) {
                Throw new AuraHandledException(e.getMessage());
            }
        }
    }