package client;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.Properties;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;

import org.jboss.ejb.client.ContextSelector;
import org.jboss.ejb.client.EJBClientContext;

import ochaloup.StatelessBeanRemote;

public class ClientUsers {

	private static String USER = "test";
	private static String PASS = "password";
	private static ContextSelector<EJBClientContext> previousSelector;

	
	private static InitialContext getOldSchoolIC(String host, String port) throws NamingException {
		host = host == null ? "127.0.0.1" : host;
		port = port == null ? "4447" : port;
        final Properties env = new Properties();
        env.put(Context.INITIAL_CONTEXT_FACTORY, org.jboss.naming.remote.client.InitialContextFactory.class.getName());
        env.put(Context.PROVIDER_URL, "remote://" + host + ":" + port);
        env.put("jboss.naming.client.ejb.context", true);
        env.put("jboss.naming.client.connect.options.org.xnio.Options.SASL_POLICY_NOPLAINTEXT", "false");
        env.put(Context.SECURITY_PRINCIPAL, ClientUsers.USER);
        env.put(Context.SECURITY_CREDENTIALS, ClientUsers.PASS);
        System.out.printf("getOldSchoolIC [user: %s, pass: %s]\n", ClientUsers.USER, ClientUsers.PASS);
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
		/*
		if(host != null) {
			prop.put("remote.connection.default.host", host);
		}
		if(port != null) {
			prop.put("remote.connection.default.port", port);
		} */
		
		prop.put("remote.connection.default.username", ClientUsers.USER);
        prop.put("remote.connection.default.password", ClientUsers.PASS);
        System.out.printf("getFancyNewIC redefined [user: %s, pass: %s]\n", ClientUsers.USER, ClientUsers.PASS);
		
		previousSelector = JNDIUtil.set(prop);
		return initialContext;
	}
	
	public static void main(String[] args) throws Exception {
		String host = args.length > 1 ? args[1] : "localhost";
		String port = args.length > 2 ? args[2] : "4447";
		StatelessBeanRemote bean = null;
		InitialContext ic = null;
		
		String userName = "";
		String password = "";
		String whichRemoting = "1";
		BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
				
		while(!"q".equals(userName.trim())) {
			String lookup = "myejb/StatelessBeanSecured!ochaloup.StatelessBeanRemote";

			try {
				if("2".equals(whichRemoting)) {
					System.out.println("Using oldschool IC");
					ic = getOldSchoolIC(host, port);
					bean = (StatelessBeanRemote) ic.lookup(lookup);
				} else if("1".equals(whichRemoting)) {
					System.out.println("Using new IC - redefined");
					ic = getFancyNewIC(host, port);
					bean = (StatelessBeanRemote) ic.lookup("ejb:/" + lookup);
				} else {
					System.out.println("Using new IC - NOT redefined");
					ic = getFancyNewICNotRedefined();
					bean = (StatelessBeanRemote) ic.lookup("ejb:/" + lookup);
				}
			
				System.out.println(bean.sayHello());
			} catch(Exception e) {
				System.out.println("Exception " + e + " was thrown.");
				System.out.println("Continuing in running...");
			} finally {
	            if (previousSelector != null) {
	                EJBClientContext.setSelector(previousSelector);
	                previousSelector = null;
	            }
	            if (ic != null) {
	            	ic.close();
	            	ic = null;
	            }
			}

	        System.out.println(" ");
			System.out.print("Username: ");
			userName = br.readLine().trim();
			if("q".equals(userName)) {
				break;
			}
			
			ClientUsers.USER = "".equals(userName) ? ClientUsers.USER : userName;
			System.out.print("Password: ");
			password = br.readLine().trim();
			ClientUsers.PASS = "".equals(password) ? ClientUsers.PASS
					: password;
			System.out.print("Which remoting [ejb=1, remote=2, ejb-from-file=3]: ");
			String whichR = br.readLine().trim();
			whichRemoting = "".equals(whichR) ? whichRemoting : whichR; 
		}
		
		System.out.println("Client finished gracefully :)");
	}
}
