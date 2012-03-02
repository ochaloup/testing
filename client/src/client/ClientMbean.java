package client;

import javax.naming.InitialContext;
import app.StatelessBeanRemote;

public class ClientMbean {

	public static void main(String[] args) throws Exception {
		InitialContext initialContext = InitialContextUtil.getInitialContext();	
		StatelessBeanRemote slsb = (StatelessBeanRemote) initialContext.lookup("ejb:/mbean//StatelessBean!app.StatelessBeanRemote");
        String msg = slsb.doSt();
        System.out.println("MSG: " + msg);
        InitialContextUtil.closeInitialContext();
	}	
}
