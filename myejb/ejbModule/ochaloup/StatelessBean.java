package ochaloup;

import java.util.Date;
import java.util.Hashtable;

import javax.ejb.Stateless;
import javax.naming.Context;

import org.jboss.logging.Logger;

@Stateless
public class StatelessBean implements StatelessBeanRemote {
	private static final Logger log = Logger.getLogger(StatelessBean.class);

	public String sayHello() {
		log.info("Saying Hello");
		return NodeNameGetter.getNodeName() +": Hello at " + (new Date()).toString();
	}

	public void callRemote() {
		log.info("Calling remote");
		
        try {
            final Hashtable<String, String> props = new Hashtable<String, String>();
            // setup the ejb: namespace URL factory
            props.put(Context.URL_PKG_PREFIXES, "org.jboss.ejb.client.naming");
            // create the InitialContext
            final Context context = new javax.naming.InitialContext(props);
 
            // Lookup the Greeter bean using the ejb: namespace syntax which is explained here https://docs.jboss.org/author/display/AS71/EJB+invocations+from+a+remote+client+using+JNDI
            final StatefulBeanRemote bean = (StatefulBeanRemote) context.lookup("ejb:" + "/" + "myejb" + "/" + "" + "/" + "StatefulBean" + "!" + StatefulBeanRemote.class.getName() + "?stateful");
             // invoke on the bean
            final String greeting = bean.called();
            log.info(greeting);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
	}
	
	public void localCall() {
		log.info("Local call");
		
        try {
            // create the InitialContext
            final Context context = new javax.naming.InitialContext();
             // Lookup the Greeter bean using the ejb: namespace syntax which is explained here https://docs.jboss.org/author/display/AS71/EJB+invocations+from+a+remote+client+using+JNDI
            final StatefulBeanRemote bean = (StatefulBeanRemote) context.lookup("ejb:" + "/" + "myejb" + "/" + "" + "/" + "StatefulBean" + "!" + StatefulBeanRemote.class.getName() + "?stateful");
             // invoke on the bean
            final String greeting = bean.called();
            log.info(greeting);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
	}
}
