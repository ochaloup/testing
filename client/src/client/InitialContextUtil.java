package client;

import java.util.Properties;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;

public class InitialContextUtil {
    private static InitialContext initialContext;   
    private static final String PKG_INTERFACES = "org.jboss.ejb.client.naming";
    
    public static InitialContext getInitialContext() throws NamingException {
    	if(initialContext == null) {
			Properties properties = new Properties();
	        properties.put(Context.URL_PKG_PREFIXES, PKG_INTERFACES);
	        System.out.println(properties);
	        initialContext = new InitialContext(properties);
    	}
    	return initialContext;
    }
    
    public static void closeInitialContext() throws NamingException {
    	initialContext.close();
    }
}
