/*--------------------------------------------------------------------------------------------------------
Author:         Rahul Chandra
Description:    Test Class for SobjectDMLEventService class.
---------------------------------------------------------------------------------------------------------*/

@isTest
public class SobjectDMLEventService_Test {
	@testSetup
    public static void testSetup(){
        
        Account acc1 = new Account(Name='Test Account');
		Account acc3 = new Account(Name='Test Account3');
		List<Account> accList=new List<Account>();
		accList.add(acc3);
		accList.add(acc1);
		insert accList;
		
               
    }
    
    public static testmethod void testPublishEvent(){
        List<Account> accUpdateList = [SELECT Id FROM Account WHERE Name='Test Account'];
		accUpdateList[0].Name='Test Updated';
        Account accInsert = new Account(Name='Test Account1');
		List<Account> accInsertList=new List<Account>();
        accInsertList.add(accInsert);
		List<Account> accUpsertList=new List<Account>();
		Account accInsert2 = new Account(Name='Test Account2');
		accUpsertList.add(accInsert2);
		List<Account> accUpdateList2 = [SELECT Id FROM Account WHERE Name='Test Account3'];
		accUpdateList2[0].Name='Test Updated3';
		accUpsertList.addAll(accUpdateList2);
        Test.startTest();
        SobjectDMLEventService.publishEvent(accInsertList,'Account',SobjectDMLEventService.INSERTX);
		SobjectDMLEventService.publishEvent(accUpdateList,'Account',SobjectDMLEventService.UPDATEX);
		SobjectDMLEventService.publishEvent(accUpsertList,'Account',SobjectDMLEventService.UPSERTX);
		SobjectDMLEventService.publishEvent(accUpdateList,'Account',SobjectDMLEventService.DELETEX);
        
        Test.stopTest();        
    }
    
    
}