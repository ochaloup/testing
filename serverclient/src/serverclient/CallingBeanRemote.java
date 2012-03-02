package serverclient;

import javax.ejb.Remote;

@Remote
public interface CallingBeanRemote {
	String call();
}
