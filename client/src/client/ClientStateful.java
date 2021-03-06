package client;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.Calendar;
import javax.naming.InitialContext;

import ochaloup.StatefulBeanRemote;


public class ClientStateful {
	public static void main(String[] args) throws Exception {
		InitialContext initialContext = InitialContextUtil.getInitialContext();
		StatefulBeanRemote sb = (StatefulBeanRemote) initialContext.lookup("ejb:/myejb//StatefulBean!ochaloup.StatefulBeanRemote?stateful");

		// int size = sb.createStringData(31457280);
		int size = sb.createStringData(3);
        Calendar cal = Calendar.getInstance();
        System.out.println("[" + cal.getTime() + ":" + cal.getTimeInMillis() + "] My size is: " + size);
        // */
        // System.out.println(EJBClientContext.requireCurrent().getClusterContext("ejb"));
        
        String a = "";
        BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
        System.out.println("Staying before while cycle");
        while(!"q".equals(a.trim())) {
        	System.out.print("Size of data is");
        	System.out.println(": " + sb.getStringDataSize());
            a = br.readLine();
        }
        
        InitialContextUtil.closeInitialContext();
	}
}
