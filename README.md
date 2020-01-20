# Externalizing HTTP Sessions to remote JDG Servers

## Prerequisites

* Java JDK installed with `JAVA_HOME` set and `java` on the $PATH
* JBoss EAP 7.1 
* JBoss Data Grid 7.1 (server)
* Firefox or Safari with developer tools to snoop on HTTP traffic

## Setup 

### Build the project 

Run the following command in the root folder of the project 

```sh 
mvn clean package
```

### Setup runtime environments

Open up a shell in the root folder of the project and run the following commands

```sh 
# Provide correct paths to the EAP and JDG server runtimes
export EAP_HOME=<path-to-eap-home-folder>
export JDG_HOME=<path-to-jdg-home-folder>

# Run the provided setup script
./scripts/setup.sh
```
THE SCRIPT WILL START TWO EAP AND TWO JDG INSTANCES.

You will see the STARTUP and SHUTDOWN COMMANDS displayed at the prompt. Save the commands as you would use them during our testing.

After the script has run successfully, the EAP nodes can be accessed at:

1. Node 1 : http://127.0.0.1:8380/http-session-counter/
2. Node 2 : http://127.0.0.1:8480/http-session-counter/ 

## Test

1. Hit the first EAP host URL couple of times via browser [![](.images/http-request-node1.png)](.images/http-request-node1.png)
2. Now, hit the second EAP host URL couple of times via browser
3. Shutdown EAP Node 1 and Node 2 and start both of them back again. You should notice the counter still intact
4. Kill one of the jdg nodes. Notice that the second jdg is still maintaining the counter, and incrementing if you hit any of the EAP URLs
5. Restart the jdg node, you will notice it joins back in the cluster, and the counter still increments
6. Kill the other jdg node and the hit the EAP URL to notice that the counter is still incrementing
7. We just externalized cache and made it highly available.
  
