package client;

import javax.naming.InitialContext;
import javax.naming.NamingException;
import ochaloup.StatelessBeanRemote8231;

public class ClientReproducer8231 {
	
	public static void main(String[] args) throws NamingException {
		InitialContext ctx = InitialContextUtil.getInitialContext();
		
		for(int i = 0; i < 1000; i++) {
			String lookup = "ejb:/reproducer-JBPAPP-8231//StatelessBean!" + StatelessBeanRemote8231.class.getName();
			StatelessBeanRemote8231 bean = (StatelessBeanRemote8231) ctx.lookup(lookup);
			int timerCountCreated = bean.createTimer("Timer " + Integer.toString(i));
			System.out.println("Number of timers created: " + Integer.toString(timerCountCreated));
			// bean.cancelTimers();
		}
	}
}
