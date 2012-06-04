package ochaloup;

import javax.ejb.Remote;

@Remote
public interface StatelessBeanRemote extends ISayHello {
	String sayHello();
	void callRemote();
	void localCall();
}
