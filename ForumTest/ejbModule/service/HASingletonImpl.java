package service;

import org.jboss.msc.service.Service;
import org.jboss.msc.service.StartContext;
import org.jboss.msc.service.StartException;
import org.jboss.msc.service.StopContext;


/**
* String node = (String) CurrentServiceContainer.getServiceContainer().getService(HASingletonImpl.SERVICE_NAME).getValue();
* @author Joe
*
*/
public class HASingletonImpl implements Service<String>{


	public String getValue() throws IllegalStateException,IllegalArgumentException {
	  return null;
	}

	public void start(StartContext context) throws StartException { 
	}

	public void stop(StopContext context) {
	}
}