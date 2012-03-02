package app;

import java.lang.management.ManagementFactory;
import java.util.Set;

import javax.ejb.Stateless;
import javax.management.MBeanInfo;
import javax.management.MBeanServer;
import javax.management.MBeanServerInvocationHandler;
import javax.management.ObjectInstance;
import javax.management.ObjectName;

import org.jboss.logging.Logger;

import ochaloup.TestMBean;

@Stateless
public class StatelessBean implements StatelessBeanRemote {
	private static Logger log = Logger.getLogger(StatelessBean.class);
	
	public String doSt() throws Exception {
		// MBeanServer platformMBeanServer = org.jboss.mx.util.MBeanServerLocator.locateJBoss(); AS5
		// MBeanServer platformMBeanServer = ManagementFactory.getPlatformMBeanServer(); AS7
		
		MBeanServer platformMBeanServer = null;
		for(MBeanServer server: javax.management.MBeanServerFactory.findMBeanServer(null)) {
			log.info("Found server: " + server + ", domain: " + server.getDefaultDomain());
	        if("DefaultDomain".equals(server.getDefaultDomain()) || "jboss".equals(server.getDefaultDomain())) {
	        	log.info("Default domain server found " + server);
	        	platformMBeanServer = server;
	        }
	    }
		
		ObjectName name = new ObjectName("jboss:name=test,type=ochaloup");
		Set<ObjectInstance> beans = platformMBeanServer.queryMBeans(name, null);
        log.info("Queried mbeans - number found: " + beans.size());
        
    	/*for( ObjectInstance instance : beans )
    	{
    	    MBeanInfo info = platformMBeanServer.getMBeanInfo( instance.getObjectName() );
    	    System.out.println("Classname: " + info.getClassName() + ", " + info.getDescription());
    	} */

		TestMBean mbean = (TestMBean) MBeanServerInvocationHandler.newProxyInstance(platformMBeanServer, name, TestMBean.class, false);
		log.info("IIIII: " + mbean.getMe());
		return "Ahoj, I'm " + mbean.getMe() + " years old";
	}
}
