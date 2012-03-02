package ochaloup;

import javax.ejb.Stateless;

@Stateless
public class StatelessBean implements StatelessBeanRemote {

	public String sayHello() {
		return "Hello";
	}

}
