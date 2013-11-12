package org.jboss.qa;

import org.jboss.logging.Logger;
import org.jboss.qa.TestStatelessBeanRemote;
import org.jboss.qa.util.Util;

import javax.ejb.EJBException;
import javax.naming.NamingException;

import org.jboss.arquillian.container.test.api.Config;
import org.jboss.arquillian.container.test.api.ContainerController;
import org.jboss.arquillian.container.test.api.Deployer;
import org.jboss.arquillian.container.test.api.Deployment;
import org.jboss.arquillian.test.api.ArquillianResource;
import org.jboss.shrinkwrap.api.ShrinkWrap;
import org.jboss.shrinkwrap.api.spec.JavaArchive;
import org.jboss.shrinkwrap.api.asset.EmptyAsset;
import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

public class TestStatelessBeanBase {
  private static final Logger log = Logger
      .getLogger(TestStatelessBeanBase.class);

  private static final String AS_QUALIFIER = "jbossas";
  private static final String DEPLOYMENT_NAME = "test";

  @ArquillianResource
  protected ContainerController controller;

  @ArquillianResource
  protected Deployer deployer;

  @Deployment(name = DEPLOYMENT_NAME, managed = false, testable = false)
  public static JavaArchive createDeployment() {
    return ShrinkWrap.create(JavaArchive.class, DEPLOYMENT_NAME + ".jar")
        .addClasses(TestStatelessBeanRemote.class, TestStatelessBean.class)
        .addAsManifestResource(EmptyAsset.INSTANCE, "beans.xml");
  }

  @Before
  public void before() throws Throwable {

  }

  @After
  public void after() throws Throwable {
    if (controller.isStarted(AS_QUALIFIER)) {
      try {
        deployer.undeploy(DEPLOYMENT_NAME);
      } finally {
        controller.stop(AS_QUALIFIER);
      }
    } else {
      log.warnf("Container %s is not started. Skipping the stop process.",
          AS_QUALIFIER);
    }
  }

  public void testStart() throws NamingException {
    String javaVmArguments = System.getProperty("server.jvm.args");
    Config config = new Config().add("javaVmArguments", javaVmArguments);

    log.info("Starting server manually");
    controller.start(AS_QUALIFIER, config.map());
  }

  public void testIsKilledAndStartedAfterwards() throws NamingException {

    String javaVmArguments = System.getProperty("server.jvm.args");
    Config config = new Config().add("javaVmArguments", javaVmArguments);

    log.info("Starting server manually");
    controller.start(AS_QUALIFIER, config.map());
    deployer.deploy(DEPLOYMENT_NAME);

    TestStatelessBeanRemote bean = Util.lookup(TestStatelessBeanRemote.class,
        TestStatelessBean.class, DEPLOYMENT_NAME);

    // calling bean method as byteman trigger to kill the JVM
    // InitialContext ic = getInitialContext();
    // TestStatelessBeanRemote bean = (TestStatelessBeanRemote)
    // iniCtx.lookup("java:global/test/TestStatelessBean");
    log.info("Calling killMe()");

    try {
      bean.killMe();
    } catch (EJBException e) {
      // supposing getting remote exception as the server is down
    }

    // let to know the arquillian that the container is stopped
    controller.kill(AS_QUALIFIER);

    // starting server after the JVM was killed
    controller.start(AS_QUALIFIER, config.map());

    log.info("Container should be started by now");
    Assert.assertTrue("Container should be started by now",
        controller.isStarted(AS_QUALIFIER));
  }
}
