package ochaloup;

import javax.ejb.Remote;

@Remote
public interface StatefulBeanRemote {
	String sayHello();
	
	int createStringData(int mbSize);
	int createData(int mbSize);	
	int getDataSize();
	int getStringDataSize();
	
	String called();	
}
