package ejb;

import javax.ejb.Stateless;

import org.jboss.ejb3.annotation.Clustered;

@Stateless
@Clustered
public class StatelessBean implements RemoteStateless {

	public String sayHello() {
		return "Hello";
	}
}
