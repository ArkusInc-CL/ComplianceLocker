/**
*   Chatter Compliance System (all classes, triggers and pages that start with ChatterCompliance)
*   @author     Arkus Dev Team
*/
public with sharing class ChatterCompliance_OwnerLookup {
    
    public String                   textToSearch        { get; set; }
    public List<User>               foundUsers          { get; set; }
    public List<Group>              foundQueues         { get; set; }
    List<Group>                  	allQueues           { get; set; }
    
    /**
    *   Constructor of the class
    */
    public ChatterCompliance_OwnerLookup(){
        textToSearch = '';
        foundUsers = new List<User>();
        foundQueues = new List<Group>();
        
        // retrieve all queues that support the chatter compliance object
        List<QueueSobject> supportedObjects = [ Select q.SobjectType, q.QueueId 
                                                From QueueSobject q 
                                                where q.SobjectType =: Schema.SObjectType.ChatterCompliance__c.getName() ];
        
        List<String> queueIds = new List<String>();
        
        for(QueueSobject q : supportedObjects){
            queueIds.add(q.QueueId);
        }
        
        allQueues = [ SELECT q.Id, q.Name FROM Group q WHERE q.Id IN: queueIds order by q.Name limit 999];
    }
    
    /**
    *   Returns the users and queues that match the text entered
    */
    public void find(){
	    
        textToSearch = textToSearch.trim();
        
	    String originalTextToSearch = textToSearch;
        
        String finalTextToSearch = '';
        
        for(String s : textToSearch.split(' ')){
        	finalTextToSearch = finalTextToSearch + ' ' + s.replaceAll('[^a-zA-Z0-9]', ''); // remove all non alphanumeric characters
        }
        
        textToSearch = finalTextToSearch.trim();
        
        if(textToSearch.length() > 50){
            textToSearch = textToSearch.substring(0, 50);
        }
        
        if(textToSearch == ''){
            foundUsers = Database.query('Select id,name from User where IsActive = true order by Name limit 999');
            foundQueues = allQueues;
        }else{
            if(textToSearch.length() < 100){
                foundUsers = Database.query('Select id,name from User where IsActive = true and (Name like '+'\'%'+textToSearch +'%\' or firstName like '+'\'%'+textToSearch +'%\' or lastName like '+'\'%'+textToSearch+'%\') order by Name limit 999');
            }
            foundQueues = new List<Group>();
            
            for(Group g : allQueues){
                if(g.Name.toLowerCase().indexOf(originalTextToSearch.toLowerCase()) != -1){
                    foundQueues.add(g);
                }
            }
        }
    }
    
    /**
    *   Resets the lists of results
    */
    public void clear(){
        textToSearch = '';
        find();
    }
    
}