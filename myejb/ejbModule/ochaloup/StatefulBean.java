package ochaloup;


import java.util.Calendar;

import javax.ejb.LocalBean;
import javax.ejb.Stateful;

import org.jboss.ejb3.annotation.Clustered;
import org.jboss.logging.Logger;

/**
 * Session Bean implementation class Stateful
 */
@LocalBean
@Stateful
@Clustered
public class StatefulBean implements StatefulBeanRemote {
	private static final Logger log = Logger.getLogger(StatefulBean.class);

	private String stringData;
	private byte[] data;
	
	public int createStringData(int size) {
		// int size = 1024 * 1024 * mbSize;
		log.info("Creating string with size " + size);
		StringBuilder sb = new StringBuilder(size);
		for (int i=0; i<size; i++) {
			sb.append('a');
		}
		stringData = sb.toString();
		log.info("["+ Calendar.getInstance().getTimeInMillis() +"] String data created: " + stringData.length());
		return stringData.length();
	}

	public int createData(int size) {
		// int size = mbSize * 1024 * 1024;
		log.info("Creating byte array with size " + size);
		data = new byte[size];
		log.info("["+ Calendar.getInstance().getTimeInMillis() +"] Byte data created: " + data.length);
		return size;
	}
	
	public int getDataSize() {
		return data.length;
	}

	public int getStringDataSize() {
		return stringData.length();
	}
	
	public String called() {
		log.info("I'm called");
		return "I was called";
	}
}
