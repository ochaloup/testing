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

		int size = sb.createStringData(3);
        Calendar cal = Calendar.getInstance();
        System.out.println("[" + cal.getTime() + ":" + cal.getTimeInMillis() + "] My size is: " + size);
        // */
        
        String a = "";
        BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
        while(!"q".equals(a.trim())) {
        	System.out.println("Size of data is: " + sb.getStringDataSize());
            a = br.readLine();
        }
        
        InitialContextUtil.closeInitialContext();
	}
}
