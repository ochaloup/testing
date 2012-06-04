package ejb;

import javax.ejb.Remote;

@Remote
public interface RemoteStateless {
	String sayHello();
}
