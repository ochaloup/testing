package ochaloup;

public interface TestMBean {
	int getMe();
	
	 // Lifecycle callbacks
    void start() throws Exception;
    void stop();
}
