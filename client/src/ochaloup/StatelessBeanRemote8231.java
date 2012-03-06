package ochaloup;
import javax.ejb.Remote;

@Remote
public interface StatelessBeanRemote8231 {
	int createTimer(String timerArg);
	void cancelTimers();
	int getNumberOfTimers();
}