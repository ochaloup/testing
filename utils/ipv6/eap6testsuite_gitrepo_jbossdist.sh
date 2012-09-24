. ~/config_repository/scripts/common/common_bash.sh
kill-jboss7

#wget http://download.lab.bos.redhat.com/devel/candidates/JBEAP/JBEAP-6.0.0-DR8/jboss-eap-6.0.0.DR8.zip

export M2_HOME=/qa/tools/opt/maven-3.0.3
export PATH=$M2_HOME/bin:$PATH
cd ${WORKSPACE}
git clone git://git.app.eng.bos.redhat.com/jbossas/jboss-as.git jboss-eap
cd jboss-eap
git checkout $tag
cp $settingsfile .

cd ${WORKSPACE}

cp $distfile .


if [ -d jboss-eap-6.0 ]; then rm -rf jboss-eap-6.0 ; fi ;
unzip -q $distfilename.zip




cd jboss-eap
export MAVEN_OPTS="-Xms512m -Xmx1303m -XX:MaxPermSize=512m"

mvn clean install -s settings.xml -Pnormal -DallTests -Dmaven.test.failure.ignore=true -Dsurefire.test.failure.ignore=true -Dmaven.repo.local=local-repo -Dsurefire.forked.process.timeout=1800 -Djboss.dist=${WORKSPACE}/jboss-eap-6.0 -fae -Dnode0=$MYTESTIP_1 -Dnode1=$MYTESTIP_2 -Dmcast=$MCAST_ADDR 
