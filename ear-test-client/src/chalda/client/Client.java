package chalda.client;

import java.util.Properties;

import javax.naming.Context;
import javax.naming.InitialContext;

import chalda.remote.IGlobalBean;

public class Client {

	public static void main(String[] args) throws Exception {
		Properties properties = new Properties();
        properties.put(Context.URL_PKG_PREFIXES, "org.jboss.ejb.client.naming");
        InitialContext initialContext = new InitialContext(properties);
			
		IGlobalBean bean = (IGlobalBean) initialContext.lookup("ejb:ear-test/ear-test-remote/GlobalCalculatorBean!chalda.remote.IGlobalBean");

		System.out.println(bean.add(10, 20));
		initialContext.close();
	}
}
