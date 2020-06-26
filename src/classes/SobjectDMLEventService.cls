/**
 * @File Name          : SobjectDMLEventService.cls
 * @Description        : This class publishes and handles platform events for DMLs
 * @Author             : Rahul Chandra 
**/
public without sharing  class SobjectDMLEventService  {

    public static final String INSERTX = 'Insert';
    public static final String UPDATEX = 'Update';
    public static final String UPSERTX = 'Upsert';
    public static final String DELETEX = 'Delete';
    //publishes event which can be of DML opertaion type Insert,Update,Delete or Upsert
    public static void publishEvent(List<Sobject> sObjectList, String objectName,String dmlOperation){
        try{

        
        List<String> jsonListofRecords=getJSONListFromSobjectList(sObjectList);
        List<SobjectDMLEvent__e> publishEventList=new List<SobjectDMLEvent__e>();
        for(String jsonSobj : jsonListofRecords){
            //create platform Event
            SobjectDMLEvent__e sobjectDMLEvent=new SobjectDMLEvent__e();
            sobjectDMLEvent.Object_API_Name__c=objectName;
            sobjectDMLEvent.DML_Operation__c=dmlOperation;
            sobjectDMLEvent.RecordJSON__c=jsonSobj;
            publishEventList.add(sobjectDMLEvent);
        }

        //publish events
        List<Database.SaveResult> results = EventBus.publish(publishEventList);
        for (Database.SaveResult sr : results) 
        {
            if (sr.isSuccess()) {
                System.debug('Successfully published SobjectDMLEvent__e.');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' + err.getStatusCode() + err.getMessage());
                    //Log the error in a log object
                }
            }
        }
    }
    catch(Exception ex){
			//Log the error in a log object
    }
    }
    //event subscribtion which performs the actions
   public static void subscribeEvent(List<SobjectDMLEvent__e> sobjectDMLEvents){
       String objectName=sobjectDMLEvents[0].Object_API_Name__c;
       try{
       
       List<String> sobjectJSONListUpdate=new List<String>();
       List<String> sobjectJSONListInsert=new List<String>();
       List<String> sobjectJSONListUpsert=new List<String>();
       List<String> sobjectJSONListDelete=new List<String>();
       for(SobjectDMLEvent__e sobjectDMLEvent : sobjectDMLEvents){

           if(sobjectDMLEvent.DML_Operation__c==SobjectDMLEventService.INSERTX){
            sobjectJSONListInsert.add(sobjectDMLEvent.RecordJSON__c);
           }
           if(sobjectDMLEvent.DML_Operation__c==SobjectDMLEventService.UPDATEX){
            sobjectJSONListUpdate.add(sobjectDMLEvent.RecordJSON__c);
           }
           if(sobjectDMLEvent.DML_Operation__c==SobjectDMLEventService.UPSERTX){
            sobjectJSONListUpsert.add(sobjectDMLEvent.RecordJSON__c);
           }
           if(sobjectDMLEvent.DML_Operation__c==SobjectDMLEventService.DELETEX){
            sobjectJSONListDelete.add(sobjectDMLEvent.RecordJSON__c);
           }

       }
       if(!sobjectJSONListUpdate.isEmpty()){
        updateSobjectRecords(sobjectJSONListUpdate);
       }
       if(!sobjectJSONListInsert.isEmpty()){
        insertSobjectRecords(sobjectJSONListInsert);
       }
       if(!sobjectJSONListUpsert.isEmpty()){
        upsertSobjectRecords(sobjectJSONListUpsert);
       }
       if(!sobjectJSONListDelete.isEmpty()){
        deleteSobjectRecords(sobjectJSONListDelete);
       }
       
    }
    catch(Exception ex){
        if(ex.getMessage().contains('UNABLE_TO_LOCK_ROW'))
        {
            if (EventBus.TriggerContext.currentContext().retries < 4) {
                // Condition isn't met, so try again later.
                throw new EventBus.RetryableException('SobjectDMLEventService Lock exception, so retrying the trigger again.');
            } else {
                //Log the error in a log object for too many tries
            }
        }
        else{
		//Log the exception in a log object for too many tries
            
        }
        
    }
       
   }

   public static void upsertSobjectRecords(List<String> sobjectAsJsonInList){
    List<Sobject> sobjectList=getSobjectListFromJSONList(sobjectAsJsonInList);
    List<Sobject> sobjectListInsert=new List<Sobject>();
    List<Sobject> sobjectListUpdate=new List<Sobject>();
    Set<Id> updateRecordsSet=new Set<Id>();
    for(Sobject sobj: sobjectList){
        if(sobj.get('Id')==null){
            sobjectListInsert.add(sobj);
        }
        else{
            Id sobjId=(Id)sobj.get('Id');
            if(!updateRecordsSet.contains(sobjId)){
                sobjectListUpdate.add(sobj);
                updateRecordsSet.add(sobjId);
            }
            
            
        }
    }
    if(!sobjectListUpdate.isEmpty()){
        update sobjectListUpdate;
    }
    if(!sobjectListInsert.isEmpty()){
        insert sobjectListInsert;
    }    
    }
    public static void updateSobjectRecords(List<String> sobjectAsJsonInList){
        List<Sobject> sobjectListUpdate=new List<Sobject>();
        Set<Id> updateRecordsSet=new Set<Id>();
        List<Sobject> sobjectList=getSobjectListFromJSONList(sobjectAsJsonInList);
        for(Sobject sobj: sobjectList){  
                Id sobjId=(Id)sobj.get('Id');    
                if(!updateRecordsSet.contains(sobjId)){
                    sobjectListUpdate.add(sobj);
                    updateRecordsSet.add(sobjId);
                }       
        }

        update sobjectListUpdate;
    }
    public static void insertSobjectRecords(List<String> sobjectAsJsonInList){
        insert getSobjectListFromJSONList(sobjectAsJsonInList);
    }
    public static void deleteSobjectRecords(List<String> sobjectAsJsonInList){
        delete getSobjectListFromJSONList(sobjectAsJsonInList);
    }
    //convert SObjectList to JSON List
    public static List<String> getJSONListFromSobjectList(List<Sobject> sObjectList)
    {
        List<String> sobjectAsJsonInList=new List<String>();
        for(SObject sObj : sObjectList)
        {
            String sobjAsJson=Json.serialize(sObj);
            sobjectAsJsonInList.add(sobjAsJson);
        }
        
        return sobjectAsJsonInList;
    }
    //convert JSON list to SOBJECT List
    public static List<Sobject> getSobjectListFromJSONList (List<String> sobjectAsJsonInList)
    {
        
            List<Sobject> sobjectList=new List<Sobject>();
            for(String jsonSobj : sobjectAsJsonInList)
            {
                
                
                
                Map<String, Object> cObjMap = (Map<String, Object>) JSON.deserializeUntyped(jsonSobj);
                
                String cObjJsonFinal = JSON.serialize(cObjMap);
                
                SObject sObjectConverted = (SObject)JSON.deserialize(cObjJsonFinal, Sobject.class);
                
                sobjectList.add(sObjectConverted);
            }
            return sobjectList;
            
            
    }

}