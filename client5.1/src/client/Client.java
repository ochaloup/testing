package client;

import javax.naming.InitialContext;
import app.StatelessBeanRemote;

public class Client {
	public static void main(String[] args) throws Exception {
		InitialContext ctx = null;
		try{
			System.out.println("Calling st...");
			ctx = new InitialContext();
			System.out.println("Intialcontext: " + ctx);
			StatelessBeanRemote bean = (StatelessBeanRemote) ctx.lookup("StatelessBean/remote");
			System.out.println("Bean: " + bean);
			String msg = bean.doSt();
			System.out.println("MSG: " + msg);
		}finally {
			if(ctx!=null)
				ctx.close();
		}
	}
}
