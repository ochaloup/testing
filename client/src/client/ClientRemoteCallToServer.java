package client;

import javax.naming.InitialContext;

import ochaloup.StatelessBeanRemote;

public class ClientRemoteCallToServer {

	public static void main(String[] args) throws Exception {
		InitialContext initialContext = InitialContextUtil.getInitialContext();		
		
		String lookup = "ejb:/myejb//StatelessBean!" + StatelessBeanRemote.class.getName();
		System.out.println("Looking for bean on: " + lookup);
		StatelessBeanRemote bean = (StatelessBeanRemote) initialContext.lookup(lookup);
		System.out.println("The bean on server says: " + bean.sayHello());
		
		InitialContextUtil.closeInitialContext();
	}
}
