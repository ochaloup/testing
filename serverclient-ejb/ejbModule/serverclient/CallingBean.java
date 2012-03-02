package serverclient;

import java.util.Properties;
import javax.ejb.Stateless;
import javax.naming.Context;
import javax.naming.InitialContext;
import org.jboss.logging.Logger;
import ochaloup.StatelessBeanRemote;

@Stateless
public class CallingBean implements CallingBeanRemote {
	private static final Logger log = Logger.getLogger(CallingBean.class);
	private static final String PKG_INTERFACES = "org.jboss.ejb.client.naming";
	
	public String call() throws Exception {
		Context context = null;
        try {
            Properties properties = new Properties();
	        properties.put(Context.URL_PKG_PREFIXES, PKG_INTERFACES);
            context = new InitialContext(properties);
 
            // Lookup the Greeter bean using the ejb: namespace syntax which is explained here https://docs.jboss.org/author/display/AS71/EJB+invocations+from+a+remote+client+using+JNDI
            final StatelessBeanRemote bean = (StatelessBeanRemote) 
            		context.lookup("ejb:/myejb//StatelessBean!" + StatelessBeanRemote.class.getName());
 
            // invoke on the bean
            final String greeting = bean.sayHello();
 
            log.info("Received greeting: " + greeting);
            return greeting;
        } catch (Exception e) {
            throw new RuntimeException(e);
        } finally {
        	if(context != null) {
        		context.close();
        	}
        }
	}

}
