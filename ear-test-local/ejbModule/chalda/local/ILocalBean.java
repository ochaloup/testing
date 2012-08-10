package chalda.local;

import javax.ejb.Local;

@Local
public interface ILocalBean {
	int add(int a, int b);
}
