package app;

import javax.ejb.Remote;

@Remote
public interface StatelessBeanRemote {
	String doSt() throws Exception;
}
