package ochaloup;

import javax.ejb.Remote;

@Remote
public interface StatelessBeanRemote {
	String sayHello();
	void callRemote();
	void localCall();
}
