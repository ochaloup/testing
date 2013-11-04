package org.jboss.qa;

import java.util.Map;

import org.jboss.qa.TestStatelessBean;

import javax.naming.NamingException;

import org.jboss.arquillian.container.test.api.Config;
import org.jboss.arquillian.container.test.api.ContainerController;
import org.jboss.arquillian.container.test.api.Deployer;
import org.jboss.arquillian.container.test.api.Deployment;
import org.jboss.arquillian.container.test.api.RunAsClient;
import org.jboss.arquillian.junit.Arquillian;
import org.jboss.arquillian.test.api.ArquillianResource;
import org.jboss.shrinkwrap.api.ShrinkWrap;
import org.jboss.shrinkwrap.api.spec.JavaArchive;
import org.jboss.shrinkwrap.api.asset.EmptyAsset;
import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.jboss.qa.util.Util;

@RunWith(Arquillian.class)
@RunAsClient
public class TestStatelessBeanTest {
   private static final String AS_QUALIFIER = "jbossas";
   private static final String DEPLOYMENT_NAME = "test";

   /* as not managed and testable deployment we need to use remote lookup
   @javax.inject.Inject
   private TestStatelessBean teststatelessbean; */
   
   @ArquillianResource
   protected ContainerController controller;

   @ArquillianResource
   protected Deployer deployer;

   @Deployment(name = DEPLOYMENT_NAME, managed = false, testable = false)
   public static JavaArchive createDeployment()
   {
      return ShrinkWrap.create(JavaArchive.class, DEPLOYMENT_NAME + ".jar")
            .addClasses(TestStatelessBean.class, TestStatelessBeanRemote.class)
            .addAsManifestResource(EmptyAsset.INSTANCE, "beans.xml");
   }

   @Before
   public void before() throws Throwable {
       // not working with clean javaVMArguments - add at lease something :)
       Map<String, String> config = new Config().add("javaVmArguments", "-Xmx512m -XX:MaxPermSize=256m").map();
       controller.start(AS_QUALIFIER, config);
       deployer.deploy(DEPLOYMENT_NAME);
   }

   @After
   public void after() throws Throwable {
       try {
         deployer.undeploy(DEPLOYMENT_NAME);
       } finally {
           controller.stop(AS_QUALIFIER);
       }
   }
   
   
   @Test
   public void testIsDeployed() throws NamingException {
     TestStatelessBeanRemote bean = Util.lookup(TestStatelessBeanRemote.class, TestStatelessBean.class, DEPLOYMENT_NAME);
      Assert.assertNotNull(bean);
      Assert.assertEquals(TestStatelessBean.HELLO_STRING, bean.sayHello());
   }
}
