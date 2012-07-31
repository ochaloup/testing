package secured;

import javax.annotation.Resource;
import javax.annotation.security.RolesAllowed;
import javax.ejb.SessionContext;
import javax.ejb.Stateless;

import ochaloup.NodeNameGetter;
import ochaloup.StatelessBeanRemote;

import org.jboss.ejb3.annotation.Clustered;
import org.jboss.ejb3.annotation.SecurityDomain;
import org.jboss.logging.Logger;

@Clustered
@Stateless
@SecurityDomain("other")
// @SecurityDomain("myDomain")
public class StatelessBeanSecured implements StatelessBeanRemote {
	private static final Logger log = Logger.getLogger(StatelessBeanSecured.class);
	
	@Resource
    private SessionContext ctx;

	@RolesAllowed({"ejb", "role1"})
	public String sayHello() {
		String principalName = ctx.getCallerPrincipal().getName();
		log.info("Saying Hello " + principalName);
		return NodeNameGetter.getNodeName() +": Hello with " + principalName;
	}

	public void callRemote() {
		throw new UnsupportedOperationException("callRemote");
	}
	
	public void localCall() {
		throw new UnsupportedOperationException("localCall");
	}
}
