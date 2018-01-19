global with sharing class ChatterCompilance_ScheduleBatch implements Schedulable, Database.Stateful{

	private Integer option;

	global ChatterCompilance_ScheduleBatch(integer batchNumber){
		this.option = batchNumber;
	}

	global void execute(SchedulableContext ctx){
		if(option == 0){
			//add parameter to batch constructor pass apexJob Id
			ChatterCompilance_FeedCommentBatch_Log batch = new ChatterCompilance_FeedCommentBatch_Log();
			Database.executeBatch(batch, 25);
		}
		else if(option == 1){
			ChatterComp_FeedItemDeleteBatch_Log batch = new ChatterComp_FeedItemDeleteBatch_Log();
			Database.executeBatch(batch, 25);
		}
		else if(option == 2){
			ChatterComp_FeedCommentDeleteBatch_Log batch = new ChatterComp_FeedCommentDeleteBatch_Log('chatcomp__ChatterComplianceComment__c');
			Database.executeBatch(batch, 25);
		}
		else if(option == 3){
			ChatterComp_FeedCommentDeleteBatch_Log batch = new ChatterComp_FeedCommentDeleteBatch_Log('chatcomp__ChatterComplianceCommentNew__c');
			Database.executeBatch(batch, 25);
		}
		//Add Customsetting To store the ScheduleJob Id
		system.abortJob(ctx.getTriggerID());
		//future method to delete the scheduled job
		try{
			ChatterCompliance_Utils.deleteScheduleJobFuture(ctx.getTriggerID());
		}
		catch(Exception e){
			system.debug('Scheduled Job Already Aborted');
		}
	}
}