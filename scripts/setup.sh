export DIRNAME=$(dirname $0)
export PROJECTDIR=`cd "$DIRNAME/.."; pwd`
export RUNTIMES=$PROJECTDIR/runtimes
export NODE1=$RUNTIMES/node1
export NODE2=$RUNTIMES/node2
export DG1=$RUNTIMES/dg1
export DG2=$RUNTIMES/dg2

if [ -z ${EAP_HOME+x} ] || [ -z ${JDG_HOME+x} ] ; then 
	echo "Either EAP_HOME or JDG_HOME variable is not set. Exiting..."	
	exit
fi

if [ ! -f $PROJECTDIR/target/http-session-counter.war ] ; then
	echo "The war file http-session-counter.war not found in the target folder!"
	echo "Run 'mvn clean package' in the root folder of this project before running this script again"
	exit
fi 

echo ">> Removing all of the existing runtime folders"
rm -rf $NODE1 $NODE2 $DG1 $DG2

echo ">> Copying the existing EAP folder as node1 and node2 respectively"
cp -R $EAP_HOME $NODE1 
cp -R $EAP_HOME $NODE2 
cp $PROJECTDIR/config/hssr-standalone-ha.xml $NODE1/standalone/configuration
cp $PROJECTDIR/config/hssr-standalone-ha.xml $NODE2/standalone/configuration
 
echo ">> Copying the existing data grid folder as dg"
cp -R $JDG_HOME $DG1
cp -R $JDG_HOME $DG2 
cp $PROJECTDIR/config/hssr-clustered.xml $DG1/standalone/configuration
cp $PROJECTDIR/config/hssr-clustered.xml $DG2/standalone/configuration

echo ">> Starting the JBoss Data Grid Server"
nohup sh $DG1/bin/standalone.sh -c hssr-clustered.xml -Djboss.socket.binding.port-offset=100 -Djboss.node.name=jdg1 > /dev/null 2>&1 &
nohup sh $DG2/bin/standalone.sh -c hssr-clustered.xml -Djboss.socket.binding.port-offset=200 -Djboss.node.name=jdg2 > /dev/null 2>&1 &

echo "*** Sleeping for 15s to let JDG be fully up ***"
sleep 15s 

echo ">> Starting the node1 EAP server"
nohup sh $NODE1/bin/standalone.sh -c hssr-standalone-ha.xml -Djboss.socket.binding.port-offset=300 -Djboss.node.name=node1 > /dev/null 2>&1 &

echo ">> Starting the node2 EAP server"
nohup sh $NODE2/bin/standalone.sh -c hssr-standalone-ha.xml -Djboss.socket.binding.port-offset=400 -Djboss.node.name=node2 > /dev/null 2>&1 &

echo ">> Cleaning the deployments folder of Node 1 and 2"
rm -rf $NODE1/standalone/deployments/*
rm -rf $NODE2/standalone/deployments/*

echo ">> Deploying the http-session-counter.war on Node 1 and 2"
cp $PROJECTDIR/target/http-session-counter.war $NODE1/standalone/deployments/
touch $NODE1/standalone/deployments/http-session-counter.war.dodeploy
cp $PROJECTDIR/target/http-session-counter.war $NODE2/standalone/deployments/
touch $NODE2/standalone/deployments/http-session-counter.war.dodeploy

echo ">> Use the following commands to startup the JDG servers :"
echo "----------"
nohup sh $DG1/bin/standalone.sh -c hssr-clustered.xml -Djboss.socket.binding.port-offset=100 -Djboss.node.name=jdg1 > /dev/null 2>&1 &
nohup sh $DG2/bin/standalone.sh -c hssr-clustered.xml -Djboss.socket.binding.port-offset=200 -Djboss.node.name=jdg2 > /dev/null 2>&1 &
echo "----------"
echo ">> Use the following commands to startup the EAP servers :"
echo "----------"
nohup sh $NODE1/bin/standalone.sh -c hssr-standalone-ha.xml -Djboss.socket.binding.port-offset=300 -Djboss.node.name=node1 > /dev/null 2>&1 &
nohup sh $NODE2/bin/standalone.sh -c hssr-standalone-ha.xml -Djboss.socket.binding.port-offset=400 -Djboss.node.name=node2 > /dev/null 2>&1 &
echo "----------"

echo ">> Use the following commands to shutdown the JDG servers :"
echo "----------"
echo "$NODE1/bin/jboss-cli.sh -c --controller=127.0.0.1:10090 --command=shutdown"
echo "$NODE2/bin/jboss-cli.sh -c --controller=127.0.0.1:10190 --command=shutdown"
echo "----------"
echo ">> Use the following commands to shutdown the EAP servers :"
echo "----------"
echo "$NODE2/bin/jboss-cli.sh -c --controller=127.0.0.1:10290 --command=shutdown"
echo "$NODE1/bin/jboss-cli.sh -c --controller=127.0.0.1:10390 --command=shutdown"
echo "----------"
