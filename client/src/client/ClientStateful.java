package client;

import java.util.Calendar;
import javax.naming.InitialContext;
import ochaloup.StatefulBeanRemote;


public class ClientStateful {
	public static void main(String[] args) throws Exception {
		InitialContext initialContext = InitialContextUtil.getInitialContext();
		StatefulBeanRemote sb = (StatefulBeanRemote) initialContext.lookup("ejb:/myejb//StatefulBean!ochaloup.StatefulBeanRemote?stateful");
        int size = sb.createStringData(30);
        Calendar cal = Calendar.getInstance();
        System.out.println("[" + cal.getTime() + ":" + cal.getTimeInMillis() + "] My size is: " + size);
        InitialContextUtil.closeInitialContext();
	}
}
