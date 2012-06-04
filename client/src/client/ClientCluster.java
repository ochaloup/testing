package client;

import javax.naming.InitialContext;

import ejb.RemoteStateless;

public class ClientCluster {
	public static void main(String[] args) throws Exception {
		InitialContext initialContext = InitialContextUtil.getInitialContext();		

		String lookup = "ejb:/cluster-ejb//StatelessBean!" + RemoteStateless.class.getName();
		System.out.println("Looking for bean on: " + lookup);
		RemoteStateless bean = (RemoteStateless) initialContext.lookup(lookup);
		System.out.println(bean.sayHello());
			
		InitialContextUtil.closeInitialContext();
	}
}
