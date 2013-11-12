package org.jboss.qa;

import javax.ejb.Remote;


@Remote
public interface TestStatelessBeanRemote {
 
  String sayHello();
  
  void killMe();
}