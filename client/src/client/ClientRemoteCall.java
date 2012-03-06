package client;

import javax.naming.InitialContext;
// import org.jboss.as.test.multinode.transaction.ClientEjbRemote;
import ochaloup.StatelessBeanRemote;

public class ClientRemoteCall {

	public static void main(String[] args) throws Exception {
		InitialContext initialContext = InitialContextUtil.getInitialContext();		
		
		/*String lookup = "ejb:/serverclient-ejb//CallingBean!" + CallingBeanRemote.class.getName();
		CallingBeanRemote bean = (CallingBeanRemote) initialContext.lookup(lookup);
		System.out.println(bean.call());
		*/
		
		/*String lookup = "ejb:/myejb//StatelessBean!" + StatelessBeanRemote.class.getName();
		StatelessBeanRemote bean = (StatelessBeanRemote) initialContext.lookup(lookup);
		System.out.println(bean.sayHello()); */
		
		/* String lookup = "ejb:/multinode-client_client_client//ClientEjb!" + ClientEjbRemote.class.getName();
		ClientEjbRemote bean = (ClientEjbRemote) initialContext.lookup(lookup);
		bean.testSameTransactionEachCall(); */
		
		String lookup = "ejb:/myejb//StatelessBean!" + StatelessBeanRemote.class.getName();
		StatelessBeanRemote bean = (StatelessBeanRemote) initialContext.lookup(lookup);
		bean.localCall();
		
		InitialContextUtil.closeInitialContext();
	}
}
