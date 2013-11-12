package org.jboss.qa.util;

import java.util.Properties;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.rmi.PortableRemoteObject;

import org.jboss.as.network.NetworkUtils;
import org.jboss.logging.Logger;

/**
 * Utility for remote lookup.
 */
public abstract class Util {
    protected static final Logger log = Logger.getLogger(Util.class);

    public static <T> T lookup(final Class<T> remoteClass, final Class<?> beanClass, final String archiveName) throws NamingException {
        return lookup(remoteClass, beanClass, "", archiveName);
    }

    /**
     * Using jboss-ejb-client.properties
     */
    public static <T> T lookup(final Class<T> remoteClass, final Class<?> beanClass, final String appName, final String archiveName) throws NamingException {
        String myContext = org.jboss.as.test.shared.integration.ejb.security.Util.createRemoteEjbJndiContext(
                appName,
                archiveName,
                "",
                beanClass.getSimpleName(),
                remoteClass.getName(),
                false);

        Context ctx = org.jboss.as.test.shared.integration.ejb.security.Util.createNamingContext();
        return remoteClass.cast(ctx.lookup(myContext));
    }
    
    /**
     * Possible lookup ways
     * check org.jboss.as.test.integration.ejb.iiop.naming.IIOPNamingTestCase in WildFly testsuite.
     */
    public static <T> T lookupIIOP(final Class<T> homeClass, final Class<?> beanClass) throws NamingException {
    	String serverName =  NetworkUtils.formatPossibleIpv6Address(System.getProperty("jbossas.addr", "localhost"));

    	// This is needed for the PortableRemoteObject.narrow method does not return 'null'
    	// WARN: IBM JDK does not know to dynamically generate IIOP stubs - they have to be generated manually before test
    	//       with rmic tool - check ibmjdk.profile in pom.xml
    	System.setProperty("com.sun.CORBA.ORBUseDynamicStub", "true");
    	
        final Properties prope = new Properties();
        prope.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.cosnaming.CNCtxFactory");
        prope.put(Context.PROVIDER_URL, "corbaloc::" + serverName +":3528/JBoss/Naming/root");
        final InitialContext context = new InitialContext(prope);
        final Object ejbHome = context.lookup(beanClass.getSimpleName());
    	
    	return homeClass.cast(PortableRemoteObject.narrow(ejbHome, homeClass));
    }
}