import java.util.Iterator;
import java.util.Map;
import java.util.Set;
import java.io.PrintWriter;

import org.apache.hadoop.mapreduce.Counter;
import org.apache.hadoop.mapreduce.CounterGroup;
import org.apache.hadoop.mapreduce.Counters;
import org.apache.hadoop.mapreduce.TaskID;
import org.apache.hadoop.mapreduce.jobhistory.JobHistoryParser;
import org.apache.hadoop.mapreduce.jobhistory.JobHistoryParser.JobInfo;
import org.apache.hadoop.mapreduce.jobhistory.JobHistoryParser.TaskInfo;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.*;
import org.codehaus.jettison.json.JSONException;
import org.codehaus.jettison.json.JSONObject;

/**
 * 
 * @author Aaron
 * This is a tool to parse jhist (Job History) files.
 * It outputs the counters into a readable JSON format
 *
 */
public class JhistToJSON {
	public static void main(String args[]) {
		try {
			String path = "";//"/home/mort/hdplogsalojahdi32st0Dec-12-1418900789/mapred/history/done/2014/12/15/000000/job_1418479492350_0031-1418672913693-pristine-word+count-1418673035092-0-256-SUCCEEDED-default-1418672922170.jhist"
			String tasksCountersFile = "";
			String globalCountersFile = "";
			if(args.length > 1) {
				path = args[0];
				tasksCountersFile = args[1];
				globalCountersFile = args[2];
			} else {
				System.err.println("USAGE: JhistToJSON path tasksCountersFile globalCountersFile");
				System.exit(1);
			}
			
			Configuration conf = new Configuration();
            Path jhistPath = new Path(path);
            LocalFileSystem localFileSystem = FileSystem.getLocal(conf);

			JobHistoryParser parser = new JobHistoryParser(localFileSystem,jhistPath);
			
			JobInfo jobInfo = parser.parse();
			JSONObject globalCounters = getGlobalCounters(jobInfo);
			Map<TaskID,JobHistoryParser.TaskInfo> tasksMap = jobInfo.getAllTasks();
			JSONObject tasksCounters = getTasksCounters(tasksMap);
			PrintWriter writer = new PrintWriter(tasksCountersFile, "UTF-8");
			PrintWriter writer2 = new PrintWriter(globalCountersFile, "UTF-8");
			writer.println(tasksCounters.toString());
			writer2.println(globalCounters.toString());
			writer.close();
			writer2.close();
		} catch (Exception e) {
			e.printStackTrace();
			System.exit(1);
		}
		System.exit(0);
	}
	
	public static JSONObject getGlobalCounters(JobInfo jobInfo) throws JSONException
	{
		JSONObject result = new JSONObject();
		result.put("JOB_ID",jobInfo.getJobId().toString());
		String jobName = jobInfo.getJobname();
		
		//Iterate over counter groups
		Counters counters = jobInfo.getTotalCounters();
		Iterator<CounterGroup> it = counters.iterator();
		while(it.hasNext()) {
			CounterGroup group = it.next();
			Iterator<Counter> itCounter = group.iterator();
			//Iterate over counters of this group
			while(itCounter.hasNext())
			{
				Counter counter = itCounter.next();
				result.put(counter.getName(),counter.getValue());
			}
		}
		
		//Data out of counters info
		result.put("job_name", jobName);
		result.put("SUBMIT_TIME", jobInfo.getSubmitTime());
		result.put("LAUNCH_TIME", jobInfo.getLaunchTime());
		result.put("FINISH_TIME", jobInfo.getFinishTime());
		result.put("TOTAL_MAPS", jobInfo.getTotalMaps());
		result.put("FAILED_MAPS", jobInfo.getFailedMaps());
		result.put("FINISHED_MAPS", jobInfo.getFinishedMaps());
		result.put("TOTAL_REDUCES", jobInfo.getTotalReduces());
		result.put("FAILED_REDUCES", jobInfo.getFailedReduces());
		result.put("JOB_PRIORITY", jobInfo.getPriority());
		result.put("USER", jobInfo.getUsername());
		
		return result;
	}
	
	public static JSONObject getTasksCounters(Map<TaskID,JobHistoryParser.TaskInfo> tasksMap) throws JSONException
	{
		JSONObject result = new JSONObject();
		Set<TaskID> tasks = tasksMap.keySet();
		Iterator<TaskID> tasksIt = tasks.iterator();
		while(tasksIt.hasNext())
		{
			TaskID task = tasksIt.next();
			TaskInfo taskInfo = tasksMap.get(task);
			JSONObject tasksCounters = new JSONObject();
			//Iterate over counter groups
			Counters counters = taskInfo.getCounters();
			Iterator<CounterGroup> it = counters.iterator();
			while(it.hasNext()) {
				CounterGroup group = it.next();
				Iterator<Counter> itCounter = group.iterator();
				//Iterate over counters of this group
				while(itCounter.hasNext())
				{
					Counter counter = itCounter.next();
					tasksCounters.put(counter.getName(),counter.getValue());
				}
			}
			tasksCounters.put("TASK_TYPE", taskInfo.getTaskType());
			tasksCounters.put("TASK_ERROR", taskInfo.getError());
			tasksCounters.put("TASK_FAILED_ATTEMPT", taskInfo.getFailedDueToAttemptId());
			tasksCounters.put("TASK_FINISH_TIME", taskInfo.getFinishTime());
			tasksCounters.put("TASK_START_TIME", taskInfo.getStartTime());
			tasksCounters.put("TASK_STATUS", taskInfo.getTaskStatus());

			result.put(task.toString(), tasksCounters);
		}
		
		return result;
	}
}
