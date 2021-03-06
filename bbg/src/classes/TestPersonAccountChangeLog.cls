/**
 * This code taken from:
 * http://www.pardot.com/faqs/crm/setting-up-salesforce-com-person-accounts-for-pardot-syncing/
 * 
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class TestPersonAccountChangeLog {

    static testMethod void LogPersonAccountChangeTest() {
       	list<Account> accounts = TestUtilities.createTestOwnerAccounts(1, false);
        accounts[0].PersonEmail = 'abc@123.com';
        accounts[0].LastName = 'PardotTestName';
        accounts[0].Email_Verified__pc = 'Yes';
        insert accounts;
        
        Account account = accounts[0];
        
        System.assertEquals(1, [SELECT COUNT() FROM pi__ObjectChangeLog__c WHERE pi__ObjectEmail__c = :account.PersonEmail AND pi__ObjectState__c = 1]);
        
        account.pi__url__pc = 'dummy';
        update account;
        
        delete account;
        System.assertEquals(1, [SELECT COUNT() FROM pi__ObjectChangeLog__c WHERE pi__ObjectEmail__c = :account.PersonEmail AND pi__ObjectState__c = 2]);
        undelete account;
        System.assertEquals(1, [SELECT COUNT() FROM pi__ObjectChangeLog__c WHERE pi__ObjectEmail__c = :account.PersonEmail AND pi__ObjectState__c = 3]);
    }

}