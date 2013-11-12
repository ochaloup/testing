package org.jboss.qa;

import javax.ejb.Stateless;

import org.jboss.logging.Logger;


@Stateless
public class TestStatelessBean implements TestStatelessBeanRemote {
  public static final Logger log = Logger.getLogger(TestStatelessBean.class);
  public static final String HELLO_STRING = "Hello";
  
  public String sayHello() {
    return HELLO_STRING;
  }
  
  public void killMe() {
    log.error("Now the container should be already killed - when you see this message something went wrong!");
  }
}