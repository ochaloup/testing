package client;

import java.util.Properties;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;

import ochaloup.StatelessBeanRemote;

public class Client {

	private static final String USER = "test";
	private static final String PASS = "password1.";

	
	private static InitialContext getOldSchoolIC(String host, String port) throws NamingException {
		host = host == null ? "127.0.0.1" : host;
		port = port == null ? "4447" : port;
        final Properties env = new Properties();
        env.put(Context.INITIAL_CONTEXT_FACTORY, org.jboss.naming.remote.client.InitialContextFactory.class.getName());
        env.put(Context.PROVIDER_URL, "remote://" + host + ":" + port);
        env.put("jboss.naming.client.ejb.context", true);
        env.put("jboss.naming.client.connect.options.org.xnio.Options.SASL_POLICY_NOPLAINTEXT", "false");
        env.put(Context.SECURITY_PRINCIPAL, USER);
        env.put(Context.SECURITY_CREDENTIALS, PASS);
        return new InitialContext(env);
	}
	
	private static InitialContext getFancyNewICNotRedefined() throws NamingException {
		Properties properties = new Properties();
        properties.put(Context.URL_PKG_PREFIXES, "org.jboss.ejb.client.naming");
		return new InitialContext(properties);
	}
	
	private static InitialContext getFancyNewIC(String host, String port) throws Exception {
		InitialContext initialContext = InitialContextUtil.getInitialContext();	
		Properties prop = new Properties();
		
		if(host != null) {
			prop.put("remote.connection.default.host", host);
		}
		if(port != null) {
			prop.put("remote.connection.default.port", port);
		}
		
		JNDIUtil.set(prop);
		return initialContext;
	}
	
	public static void main(String[] args) throws Exception {
		String host = args.length > 1 ? args[1] : "localhost";
		String port = args.length > 2 ? args[2] : "4447";
		StatelessBeanRemote bean = null;
		InitialContext ic = null;
		
		String lookup = "myejb/StatelessBean!ochaloup.StatelessBeanRemote";
		// String lookup = "myejb/StatelessBeanSecured!ochaloup.StatelessBeanRemote";
		if(args.length > 0 && args[0].trim().equals("1")) {
			ic = getOldSchoolIC(host, port);
			bean = (StatelessBeanRemote) ic.lookup(lookup);
		} else if(args.length > 0 && args[0].trim().equals("2")) {
			ic = getFancyNewIC(host, port);
			bean = (StatelessBeanRemote) ic.lookup("ejb:/" + lookup);
		} else {
			ic = getFancyNewICNotRedefined();
			bean = (StatelessBeanRemote) ic.lookup("ejb:/" + lookup);
		}

		System.out.println(bean.sayHello());
        ic.close();
	}
}
