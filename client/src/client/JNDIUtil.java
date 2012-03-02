package client;

import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;
import org.jboss.ejb.client.ContextSelector;
import org.jboss.ejb.client.EJBClientConfiguration;
import org.jboss.ejb.client.EJBClientContext;
import org.jboss.ejb.client.PropertiesBasedEJBClientConfiguration;
import org.jboss.ejb.client.remoting.ConfigBasedEJBClientContextSelector;

public class JNDIUtil {
	public static ContextSelector<EJBClientContext> set(Properties propertiesToMerge) throws IOException {
        // setup the selector
        final String clientPropertiesFile = "jboss-ejb-client.properties";
        final InputStream inputStream = JNDIUtil.class.getClassLoader().getResourceAsStream(clientPropertiesFile);
        if (inputStream == null) {
            throw new IllegalStateException("Could not find " + clientPropertiesFile + " in classpath");
        }
        final Properties properties = new Properties();
        properties.load(inputStream);
        
        
        // Merging properties from method argument
        if(propertiesToMerge == null) {
            propertiesToMerge = new Properties();
        }
        for(Object key: propertiesToMerge.keySet()) {
            properties.put(key, propertiesToMerge.get(key));
            System.out.println("Adding/replacing property: " + key + " => " + propertiesToMerge.get(key));
        }
        
        for(Object obj: properties.keySet()) {
        	System.out.println(obj + " => " + properties.getProperty((String) obj));
        }
        
        final EJBClientConfiguration ejbClientConfiguration = new PropertiesBasedEJBClientConfiguration(properties);
        final ConfigBasedEJBClientContextSelector selector = new ConfigBasedEJBClientContextSelector(ejbClientConfiguration);
        System.out.println("Setting new context selector " + selector);
        return EJBClientContext.setSelector(selector);

	}
}
