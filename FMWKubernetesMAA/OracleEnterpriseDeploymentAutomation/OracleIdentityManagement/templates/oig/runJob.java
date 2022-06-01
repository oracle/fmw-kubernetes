/*
 *  Copyright (c) 2021, Oracle and/or its affiliates.
 *  Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
 * 
 * This is an example of a Java script to run an OIG Job Now
 * 
 */
import java.util.HashMap;
import java.util.Hashtable;
import java.util.Properties;
import java.util.Set;
import java.util.concurrent.TimeUnit;

import oracle.iam.platform.OIMClient;
import oracle.iam.scheduler.api.SchedulerService;
import oracle.iam.scheduler.exception.SchedulerException;
import oracle.iam.scheduler.vo.JobDetails;
import oracle.iam.scheduler.vo.JobParameter;
import oracle.iam.scheduler.vo.ScheduledTask;
import oracle.iam.scheduler.vo.JobHistory;

public class runJob {
	private static OIMClient oimClient = null;
	private static SchedulerService schedulerService;

	static public void main(String[] args) {
		
		String serverURL = args[0];
		String userName = args[1];
		String passwd = args[2];
		String jobName = args[3];
		
		try {
			String ctxFactory = "weblogic.jndi.WLInitialContextFactory";
			
			System.out.println("Server URL is : " + serverURL);
			System.out.println("Context Factory is : " + ctxFactory);
			Hashtable env = new Hashtable();
			env.put(OIMClient.JAVA_NAMING_PROVIDER_URL, serverURL);
			env.put(OIMClient.JAVA_NAMING_FACTORY_INITIAL, "weblogic.jndi.WLInitialContextFactory");
			oimClient = new OIMClient(env);
			
			oimClient.login(userName, passwd);
			System.out.println("Connected as "+userName);
		} catch (Exception e) {
			e.printStackTrace();
		}
		
		System.out.println("Running Job: "+jobName);
		
		schedulerService = (SchedulerService) oimClient.getService(SchedulerService.class);
                
		//System.out.println("Scheuler Service : " + schedulerService);
                JobDetails[] user_operations_jobs;
                ScheduledTask user_operations_task;
            
		//System.out.println("before try ");
                HashMap<String, JobParameter> taskParams;
		try {
                   user_operations_jobs = schedulerService.getJobsOfSchedulerTask(jobName);
                   for (JobDetails user_operation_job : user_operations_jobs) {
                             HashMap<String, JobParameter> jobParams = user_operation_job.getParams();
		             schedulerService.triggerNow(user_operation_job.getName());
                             TimeUnit.SECONDS.sleep(30);
		             JobHistory jobHistory = schedulerService.getLastHistoryOfJob(user_operation_job.getName());
                             System.out.println("Start Time:"+jobHistory.getJobStartTime());
                             System.out.println("End Time:"+jobHistory.getJobEndTime());
                             switch (Integer.parseInt(jobHistory.getStatus()) )
                             {
                                 case 1:
                                  System.out.println("Status: Started");
                                  break;
                                 case 2:
                                  System.out.println("Status: Success");
                                  break;
                                 case 3:
                                  System.out.println("Status: None");
                                  break;
                                 case 4:
                                  System.out.println("Status: Paused");
                                  break;
                                 case 5:
                                  System.out.println("Status: Running");
                                  break;
                                 case 6:
                                  System.out.println("Status: Failed");
                                  break;
                                 case 7:
                                  System.out.println("Status: interrupt");
                                  break;
                             }
         
	           }	
            
		   


		} catch (Exception e) {
			e.printStackTrace();
		}
		
	}

}
