package client;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.Calendar;
import java.util.Properties;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;

import ochaloup.StatefulBeanRemote;


public class ClientStateful {
	
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
		StatefulBeanRemote sb = (StatefulBeanRemote) initialContext.lookup("ejb:/myejb//StatefulBean!ochaloup.StatefulBeanRemote?stateful");

		// int size = sb.createStringData(31457280);
		int size = sb.createStringData(3);
        Calendar cal = Calendar.getInstance();
        System.out.println("[" + cal.getTime() + ":" + cal.getTimeInMillis() + "] My size is: " + size);
        // */
        // System.out.println(EJBClientContext.requireCurrent().getClusterContext("ejb"));
        
        String a = "";
        BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
        System.out.println("Staying before while cycle");
        while(!"q".equals(a.trim())) {
        	System.out.print("Size of data is");
        	System.out.println(": " + sb.getStringDataSize());
            a = br.readLine();
        }
        
        closeInitialContext();
	}
}
