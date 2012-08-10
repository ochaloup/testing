package chalda.remote;

import javax.ejb.EJB;
import javax.ejb.Stateless;

import chalda.local.ILocalBean;

@Stateless(name = "GlobalCalculatorBean")
public class GlobalBean implements IGlobalBean {
	private @EJB ILocalBean calculator;

	@Override
	public int add(int a, int b) {
		return calculator.add(a, b);
	}
	
	
}
