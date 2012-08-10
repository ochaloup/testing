package chalda.remote;

import javax.ejb.Remote;

@Remote
public interface IGlobalBean {
	int add(int a, int b);
}
