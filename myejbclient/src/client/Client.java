package client;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.Properties;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;

import ochaloup.ISayHello;
import ochaloup.StatefulBeanRemote;
import ochaloup.StatelessBeanRemote;


public class Client {
	
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
	
	
	public static void main(String[] args) throws Exception {
		InitialContext initialContext = getInitialContext();
		
		ISayHello sayHello = null;
		if(args.length > 1 && args[0].trim().equals("2")) {
			sayHello = (StatefulBeanRemote) initialContext.lookup("ejb:/myejb//StatefulBean!ochaloup.StatefulBeanRemote?stateful");
		} else {
			sayHello = (StatelessBeanRemote) initialContext.lookup("ejb:/myejb//StatelessBean!ochaloup.StatelessBeanRemote");
		}
       
        String a = "";
        BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
        System.out.println("Staying before while cycle");
        while(!"q".equals(a.trim())) {
        	System.out.println(sayHello.sayHello());
            a = br.readLine();
        }
        
        closeInitialContext();
	}
}
