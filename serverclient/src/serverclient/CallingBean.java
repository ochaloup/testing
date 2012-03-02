package serverclient;

import java.util.Hashtable;

import javax.ejb.Stateless;
import javax.naming.Context;

import org.jboss.logging.Logger;

import ochaloup.StatelessBeanRemote;

@Stateless
public class CallingBean implements CallingBeanRemote {
	private static final Logger log = Logger.getLogger(CallingBean.class);
	
	public String call() {	
        try {
            final Hashtable<String, String> props = new Hashtable<String, String>();
            // setup the ejb: namespace URL factory
            props.put(Context.URL_PKG_PREFIXES, "org.jboss.ejb.client.naming");
            /*
            props.put(Context.SECURITY_PRINCIPAL, "test");
            props.put(Context.SECURITY_CREDENTIALS, "password");
            */
            // create the InitialContext
            final Context context = new javax.naming.InitialContext(props);
 
            // Lookup the Greeter bean using the ejb: namespace syntax which is explained here https://docs.jboss.org/author/display/AS71/EJB+invocations+from+a+remote+client+using+JNDI
            final StatelessBeanRemote bean = (StatelessBeanRemote) context.lookup("ejb:/myejb//StatelessBean!" + StatelessBeanRemote.class.getName());
 
            // invoke on the bean
            final String greeting = bean.sayHello();
 
            log.info("Received greeting: " + greeting);
            return greeting;
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
	}

}
