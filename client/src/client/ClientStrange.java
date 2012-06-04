package client;

import java.util.Hashtable;
import java.util.Properties;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;

import org.jboss.as.test.clustering.cluster.ejb3.stateless.bean.Stateless;
import org.jboss.ejb.client.ContextSelector;
import org.jboss.ejb.client.EJBClientContext;
import org.jboss.ejb.client.PropertiesBasedEJBClientConfiguration;
import org.jboss.ejb.client.remoting.ConfigBasedEJBClientContextSelector;

import ochaloup.StatelessBeanRemote;

public class ClientStrange {

	private static final String USER = "test";
	private static final String PASS = "password";
	
	private static final String NODE_1 = "node-0";
	private static final String NODE_2 = "node-1";
	
	private static final String MODULE_NAME = "remote-ejb-client-stateless-bean-failover-test";

	
	public static void main(String[] args) throws Exception {
		String host = args.length > 1 ? args[1] : "127.0.0.1";
		String port = args.length > 2 ? args[2] : "4447";
		
        Properties properties = new Properties();

        properties.put("endpoint.name", "farecompare-client-endpoint");
        properties.put("remote.connectionprovider.create.options.org.xnio.Options.SSL_ENABLED", "false");

        properties.put("remote.connections", NODE_1 + "," + NODE_2);
        properties.put("remote.connection." + NODE_1 + ".host", host);
        properties.put("remote.connection." + NODE_1 + ".port", "4447");
        // properties.put("remote.connection." + NODE_1 + ".connect.options.org.xnio.Options.SASL_POLICY_NOANONYMOUS", "false");
        // properties.put("remote.connection." + NODE_1 + ".connect.options.org.xnio.Options.SASL_POLICY_NOPLAINTEXT", "false");

        // properties.put("remote.connection." + NODE_2 + ".host", host);
        // properties.put("remote.connection." + NODE_2 + ".port", "4547");
        // properties.put("remote.connection." + NODE_2 + ".connect.options.org.xnio.Options.SASL_POLICY_NOANONYMOUS", "false");
        // properties.put("remote.connection." + NODE_2 + ".connect.options.org.xnio.Options.SASL_POLICY_NOPLAINTEXT", "false");
        
        /* properties.put("remote.clusters", "ejb");
        properties.put("remote.cluster.ejb.connect.options.org.xnio.Options.SASL_POLICY_NOANONYMOUS", "false");
        properties.put("remote.cluster.ejb.connect.options.org.xnio.Options.SASL_POLICY_NOPLAINTEXT", "false"); */

        PropertiesBasedEJBClientConfiguration configuration = new PropertiesBasedEJBClientConfiguration(properties);

        final ContextSelector<EJBClientContext> ejbClientContextSelector = new ConfigBasedEJBClientContextSelector(configuration);

        final Hashtable<String, String> jndiProperties = new Hashtable<String, String>();
        jndiProperties.put(Context.URL_PKG_PREFIXES, "org.jboss.ejb.client.naming");
        final Context localContext = new InitialContext(jndiProperties);

        final ContextSelector<EJBClientContext> previousSelector = EJBClientContext.setSelector(ejbClientContextSelector);

        // Stateless bean = context.lookupStateless(StatelessBean.class, Stateless.class);
        Stateless bean = (Stateless) localContext.lookup("ejb:/" + MODULE_NAME + "/StatelessBean!" + Stateless.class.getName());

		System.out.println(bean.getNodeName());
		System.out.println(bean.getNodeName());
		System.out.println(bean.getNodeName());
		System.out.println(bean.getNodeName());
		System.out.println(bean.getNodeName());
		System.out.println(bean.getNodeName());
		System.out.println(bean.getNodeName());
		System.out.println(bean.getNodeName());
		System.out.println(bean.getNodeName());
		localContext.close();
	}
}
