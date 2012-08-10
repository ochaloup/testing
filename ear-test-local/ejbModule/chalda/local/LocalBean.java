package chalda.local;

import javax.ejb.Stateless;

@Stateless(name = "LocalCalculatorBean")
public class LocalBean implements ILocalBean {
	public int add(int a, int b) {
		return a + b;
	}

}
