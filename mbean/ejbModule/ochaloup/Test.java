package ochaloup;

public class Test implements TestMBean {
	private int me = 0;
	
	public int getMe() {
		return me;
	}

	public void start() throws Exception {
		me = 42;
	}

	public void stop() {
		// that's really nic method
	}

}
