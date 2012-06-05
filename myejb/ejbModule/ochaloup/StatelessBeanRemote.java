package ochaloup;

import javax.ejb.Remote;

@Remote
public interface StatelessBeanRemote extends ISayHello {
	void callRemote();
	void localCall();
}
