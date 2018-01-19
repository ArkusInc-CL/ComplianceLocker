global with sharing class ChatterCompliance_MessageScheduleJob implements Schedulable{


    public ChatterCompliance_MessageScheduleJob(String myTimeValue){
        
    }

    global void execute(SchedulableContext SC) {
    
        try{
            ChatterCompliance_PrivateMessagesBatch b = new ChatterCompliance_PrivateMessagesBatch();
            Database.executeBatch(b, 50);
        }catch(Exception e){}
    
        
   }
   
   /*
    static testMethod void testMessageScheduleJob(){
        
        ChatterCompliance_MessageScheduleJob c = new ChatterCompliance_MessageScheduleJob('no value');
        
        c.execute(null);
        
        system.assert(c != null);
    }
*/

}