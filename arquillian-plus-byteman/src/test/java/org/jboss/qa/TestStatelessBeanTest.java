package org.jboss.qa;

import org.jboss.logging.Logger;
import javax.naming.NamingException;

import org.jboss.arquillian.junit.Arquillian;
import org.junit.Test;
import org.junit.runner.RunWith;

@RunWith(Arquillian.class)
public class TestStatelessBeanTest extends TestStatelessBeanBase{
  private static final Logger log = Logger.getLogger(TestStatelessBeanTest.class);

  @Test
  public void ttest() throws NamingException {
    log.info("ttest");
    testIsKilledAndStartedAfterwards();
  }
}
