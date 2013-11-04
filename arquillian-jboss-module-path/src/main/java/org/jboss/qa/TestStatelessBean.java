package org.jboss.qa;

import javax.ejb.Stateless;

@Stateless
public class TestStatelessBean implements TestStatelessBeanRemote {
  public static final String HELLO_STRING = "Hello";
  
  public String sayHello() {
    return HELLO_STRING;
  }
}