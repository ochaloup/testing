set +x
. ~/config_repository/scripts/common/common_bash.sh
kill-jboss7
set -x

# getting ipv6 variables
# we should have variables: IPV6_ADDR_HOST, IPV6_ADDR_GLOBAL, IPV6_ADDR_SITE, IPV6_ADDR_LINK, IPV6_ADDR_LINK_ZONEID
. /home/hudson/users-tmp/ochaloup/ipv6/ipv6names.sh

# more memory for maven is necessary for compiling
export MAVEN_OPTS="-Xmx1024m -Xms512m -XX:MaxPermSize=128m"
export M2_HOME=/qa/tools/opt/maven-3.0.3

EAP6_ZIP=jboss-eap-6.0.0.${EAP6_BUILD}.zip
EAP6_MVN_SETTINGS=/home/hudson/static_build_env/eap/6.0.0.${EAP6_BUILD}/settings.xml
EAP6_PATH=`pwd`/jboss-eap-6.0

export PATH=$M2_HOME/bin:$PATH

cd ${WORKSPACE}

# cleaning and unzipping eap
rm -rf *
unzip -q /home/hudson/static_build_env/eap/6.0.0.${EAP6_BUILD}/${EAP6_ZIP}
unzip -q /home/pjanouse/hudson-repos/eap-ts-${EAP6_BUILD}.zip

# changing folder to folder with testsuite
cd ${WORKSPACE}/jboss-eap

# start to execute tests (this missing - not possible to do now with $IPV6_ADDR_LINK_ZONEID - JBPAPP-8833)
ADDRESSES=( $IPV6_ADDR_HOST $IPV6_ADDR_GLOBAL $IPV6_ADDR_SITE $IPV6_ADDR_LINK  ) 
# remote jndi calls - calling for all addresses defined in $ADDRESSES array
for A in "${ADDRESSES[@]}"; do 
  if [ "x$A" != "x" ]; then
    echo "Using address $A"

    # run the server
    nohup sh ${EAP6_PATH}/bin/standalone.sh -c=standalone-full.xml -Djboss.node.name=testingnode -Djboss.bind.address=$A -Djboss.bind.address.management=$A -Djboss.bind.address.unsecure=$A -Djava.net.preferIPv4Stack=false -Djava.net.preferIPv6Addresses=true &

    # simple busy waiting till server is started
    LOOP=10
    while [ $LOOP -gt 0 ]; do
      LOOP=$((LOOP-1))
      RET=1
      # 2>&1 /dev/null
      sh ${EAP6_PATH}/bin/jboss-cli.sh -c command=:read-attribute\(name=server-state\) --controller=[$A]:9999 || RET=0
      if [ "x$RET" = "x1" ]; then
        LOOP=-1
      else 
        sleep 3
      fi
      echo "We are here!"
    done

    # run the test
    sh integration-tests.sh clean install -s /home/hudson/static_build_env/eap/6.0.0.${EAP6_BUILD}/settings.xml -P public-repositories,public-plugin-repositories -Dsurefire.forked.process.timeout=1800 -Dmaven.repo.local=local-repo -Dipv6 -Dnode0=$A -Dts.noSmoke -Dts.basic -Dtest=org.jboss.as.test.integration.ejb.remote.jndi.*
    # mvn install -s /home/hudson/static_build_env/eap/6.0.0.${EAP6_BUILD}/settings.xml -B -fae -Dmaven.test.failure.ignore=true -Dmaven.repo.local=local-repo -Djboss.dist=${EAP6_PATH} -Dsurefire.forked.process.timeout=1800 -Dipv6 -Dnode0=$A -Dtest="org.jboss.as.test.integration.ejb.remote.jndi.*" -DfailIfNoTests=false -DallTests
    # mvn clean install -s /home/hudson/static_build_env/eap/6.0.0.${EAP6_BUILD}/settings.xml -Dmaven.repo.local=local-repo -Dsurefire.forked.process.timeout=1800 -Dipv6 -Dnode0=$A -Dts.noSmoke -Dts.basic -Dtest="org.jboss.as.test.integration.ejb.remote.jndi.*" 

    # stop the server
    sh ${EAP6_PATH}/bin/jboss-cli.sh --connect command=:shutdown --controller=[$A]:9999

    echo "This address is finally done - HOORAY!!!: $A"
  fi
done

exit

# server-to-server calls
# definition of bash command
CALL="mvn install -s /home/hudson/static_build_env/eap/6.0.0.${EAP6_BUILD}/settings.xml -B -fae -Dmaven.test.failure.ignore=true -Dmaven.repo.local=local-repo -Djboss.dist=${EAP6_PATH} -Dsurefire.forked.process.timeout=1800 -Dipv6 -Dts.allTests -DfailIfNoTests=false -Dtest=org.jboss.as.test.multinode.remotecall.* -Dnode0=%s -Dnode1=%s"
# evaluation of command with "parameters"
eval `printf "$CALL" "$IPV6_ADDR_SITE" "$IPV6_ADDR_SITE"`
eval `printf "$CALL" "$IPV6_ADDR_LINK" "$IPV6_ADDR_LINK"`
eval `printf "$CALL" "$IPV6_ADDR_LINK" "$IPV6_ADDR_SITE"`
eval `printf "$CALL" "$IPV6_ADDR_SITE" "$IPV6_ADDR_SITE"`
