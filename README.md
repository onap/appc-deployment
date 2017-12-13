# ONAP APPC

---
---

# Introduction

The Application Controller (APPC) is one of the components in the ONAP Platform. Its main function is to perform functions to control the lifecycle of Virtual Functions (VNFs) as well as the components that make up these functions. Therefore, this allows the cloud to be abstracted from Virtual Functions in order to enable repeatable actions, as well as enabling automation and a dynamic configuration approach.

ONAP APPC is delivered with **3 Docker Containers**, which are deployed using Docker Images already containing the APPC Framework Suite.
NOTE: All three containers are hosted on Ubuntu 14.04 LTS OS.

# Deployment Mode for APPC
The docker containers described above are set up to be deployed on the same Virtual Machine. **Docker Compose** is Docker's deployment tool that allows to configure and deploy multiple containers at once.

# Compiling and Building APPC

APPC (structured as a Maven project) uses the Maven tool to help compile, build, and deploy APPC Artifacts (usually made up of Java packages) into a Maven Repository. In order to compile and build APPC, a `mvn clean install` is executed, which checks for any errors and Java exceptions during compilation process.

# Deploying APPC
In order to deploy APPC, a Docker-ready machine needs to be available in order to deploy the APPC Docker Containers. The following will help explain the requirements in order to run Docker to deploy these containers.

### APPC Docker Containers
ONAP APPC docker images are currently stored on the Rackspace Nexus Docker Registry (Maven Repository). The deployment code can be found in the Maven Project that builds and deploys the Docker Images to be deployed in the Nexus Repository (current approach is by using Jenkins). These Docker Images are composed of the APPC Artifacts (org.onap.appc.*) compiled and packaged in the "appc" git repository.

The following Docker images are the actual deployment images used for running APPC:
- **APPC Container**: This Docker container carries the APPC Core Framework (OpenDaylight, Karaf, OSGI Bundles, ODL Functions/APIs, and APPC specific features). This image is built on top of the SDN-C Docker Image, which contains core features (such as dblib as the Database Connector, SLI - the Service Logic Interpreter, and the Active & Available Inventory (A&AI) Listener). Some of these inherited SDN-C features/artifacts are necessary dependencies to build and compile APPC features/artifacts.
- **MySQL DB Container (Version 5.6)**: This is the database for APPC. It is currently using MySQL Community Version (Open-Source version).
- **Node Red / DGBuilder**:  This container has the visual tool used to assemble DGs in order to put together flows or services used to serve Virtual Functions. NOTE: This container is deployed using a Docker Image that is managed and supported by the SDN-C component.

# Starting APPC

Ther following steps are needed to deploy and start ONAP APPC:

##### Requirement to Pre-Define properties before compiling APPC:
- The following maven properties are not defined by default, since they change based on where the platform is being deployed:
    - ${openecomp.nexus.url}: URL of the Nexus Repository where APPC Code is at.
    - ${openecomp.nexus.port}: Port number of the Nexus Repository where APPC Code is at.
    - ${openecomp.nexus.user}: Username ID of the Nexus Repository where APPC Code is at.
    - ${openecomp.nexus.password}: Password of the Nexus Repository where APPC Code is at.

##### Using Jenkins Jobs to set up APPC Package
- A Jenkins instance for ONAP is required, in which Jenkins Jobs for both the APPC core code and deployment code are maintained.

- Jenkins Job for APPC Core git project: The Jenkins Job for the APPC git repository (Core Component) is in charge of compiling and uploading/deploying successfully compiled maven APPC artifacts into a Nexus/Maven Repository.

- Jenkins Job for APPC Deployment git project: The Jenkins Job is used to run the APPC Deployment code which ultimately builds and deploy the APPC Docker Image. Once the Jenkins job runs successfully, the newly compiled images are uploaded to the Nexus Repository. The APPC Docker image contains all the SDN-C and APPC artifacts needed to deploy a successful APPC Component.
    - With this job, all required and newly compiled and uploaded (to Nexus Repository) APPC features from the Jenkins job are pulled into the images and installed in an automated fashion.

- As explained in the "APPC Docker Containers" section, the configuration and set up of the other two docker containers are not maintained by APPC. MySQL Docker Image is maintained by the Open Source MySQL Community and the Node Red / DGBuilder Docker Image is maintained by SDN-C.

##### Using Docker to start APPC Package

- The VM where APPC will be started needs to have Docker Engine and Docker-Compose installed (instructions on how to set Docker Engine can be found [here](https://docs.docker.com/engine/installation/)). The stable version of Docker Engine where APPC has been tested to work is v1.12. An important requirement in order to access the Docker Image Repository on Nexus Repository (where docker images are currently stored) need to include the Nexus repository certificate imported in the host VM. This is needed for Docker to be able to access the Docker Images required (NOTE: MySQL Docker Image is obtained from the public Docker Hub).

- NOTE ON "docker-compose" COMMANDS: The only work if there is a provided docker-compose YAML script in the cmd path

- In order to deploy containers, the following steps need to be taken in your host VM (Assuming instructions on how to set up Docker Engine have already been done):

```bash
# Install Docker-Compose
apt-get install python-pip
pip install docker-compose

# Login to Nexus Repo to pull Docker Images (this assumes that Nexus Certificate is already imported in the Host VM on /usr/local/share/ca-certificates/ path):
docker login <DOCKER_REGISTRY_REPO> # prompts for user credentials as a way to authenticate

# Pull latest version of Docker Images (separately)
docker pull <APPC_DOCKER_IMAGE_URL>
docker pull mysql/mysql-server:5.6 # Default Open-Source MySQL Docker Image
docker pull <SDNC_DOCKER_IMAGE_URL>

# Pull latest version of Docker Images
docker-compose pull

# Deploy Containers
docker-compose up  # add -d argument to start process as a daemon (background process)
```

##### Using Docker to stop APPC Package

- The following steps are required to stop the APPC package:

```bash
# Stop and Destroy Docker Containers (with docker-compose YAML script)
docker-compose down

# Stop Docker Containers (without docker-compose YAML script)
docker stop <APPC_DOCKER_CONTAINER>
docker stop <MYSQL_DOCKER_CONTAINER>
docker stop <DGBUILDER_DOCKER_CONTAINER>

# Destroy Docker Containers (without docker-compose YAML script)
docker rm <APPC_DOCKER_CONTAINER>
docker rm <MYSQL_DOCKER_CONTAINER>
docker rm <DGBUILDER_DOCKER_CONTAINER>
```

- NOTE: To get a feel of how the deployment is actually performed, it is best to review the Docker Strategy of APPC and look at the actual Jenkins Jobs.

#### Other Useful Docker Commands

- The commands below are useful to test or troubleshoot in case a change in the gitlab code breaks a clean APPC deployment:

```bash
# Check current docker-compose logs generated during 'docker-compose up' process:
docker-compose logs # add -f to display logs in real time

# Check out docker container's current details
docker inspect <DOCKER_CONTAINER>

# Verbose output during docker-compose commands
docker-compose --verbose <DOCKER_COMPOSE_CMD_ARG>

# Check previous docker volumes
docker volume ls

# Delete previous docker volume(s)
docker volume rm <DOCKER_VOL_ID_1> <DOCKER_VOL_ID_2> ... <DOCKER_VOL_ID_N>
```

## ONAP Heat Template

A Heat template that can be used on RackSpace to spin up the APPC Host VM as well as the other ONAP Components is available in gitlab. This template would orchestrate the deployment of all ONAP components, which will trigger docker instantiation techniques to start up the containers (either standard docker or docker-compose - depending on how the component's containers get spun up).

# Validating APPC Installation

First of all, APPC Features come in the form of Karaf Features (an ODL-OpenDaylight package) which can be composed of one or more OSGI bundles. These features get installed in the ODL framework in order to be used and installed in the APPC Docker Container (NOTE: SDN-C Core Features also get installed since APPC docker image uses the SDN-C Core docker image as a base image). 

### Accessing docker containers

The following command is used to log in / access the docker containers:

```bash
docker exec -it <DOCKER_CONTAINER> bash
```

### Checking if APPC Features are installed successfully

The following commands are used to check if the APPC (and SDN-C) Bundles and Features have been installed correctly in ODL (make sure to enter the APPC Docker Container shell session):

```bash
# All commands are done inside the appc docker container

# Enter the ODL Karaf Console
cd /opt/opendaylight/current/bin
./client -u karaf

# Check if features have been installed or not (the ones with an 'X' in the "Installed" column have been successfully installed)
feature:list | grep appc # filter appc features only
feature:list | grep sdnc # filter sdn-c features only

# Check if bundles have been loaded successfully (the ones with 'Active' in the "State" column have been successfully loaded)
bundle:list | grep appc # filter appc bundles only
bundle:list | grep sdnc # grep sdn-c bundles only

# Check reason why bundle failed to load
bundle:diag | grep <BUNDLE_NAME>
```

### Accessing the API Explorer
The API Explorer is a GUI provided by OpenDaylight Open Source Framework. This GUI is very useful to send API calls from APIs that are either developed by APPC or SDN-C frameworks. In order to make these REST calls, some APIs use the [RESTCONF](http://sdntutorials.com/what-is-restconf/) protocol to make such calls.

Currently, the APIs that have a Directed Graph (DG) mapped to it are the ones that can be tested which are the SDN-C APIs and APPC "appc-provider" APIs (LCM APIs will be available to test in later releases).

In order to access this GUI, you need to go to the following website which will prompt for ODL user credentials in order to authenticate (more details on generic API Explorer [here](https://wiki.opendaylight.org/view/OpenDaylight_Controller:MD-SAL:Restconf_API_Explorer)):

- http://localhost:8282/apidoc/explorer/index.html (change localhost to your VM's public IP).

# APPC Configuration Model

APPC Configuration model involves using "default.properties" files (which are usually located in each of the APPC Features - ../<APPC_FEATURE_BUNDLE>/src/<MAIN_OR_TEST>/resources/org/onap/appc/default.properties) for APPC Feature that have default (or null) property values inside the core APPC code. These default (or null) properties should be overwritten in the properties file called "appc.properties" located in the APPC Deployment code (../installation/src/main/appc-properties/appc.properties).

Each APPC component depends on the property values that are defined for them in order to function properly. For example, the APPC Feature "appc-rest-adapter" located in the APPC Core repo is used to listen to events that are being sent and received in the form of DMaaP Messages through a DMaaP Server Instance (which is usually defined as a RESTful API Layer over the Apache Kafka Framework). The properties for this feature need to be defined to point to the right DMaaP set of events to make sure that we are sending and receiving the proper messages on DMaaP.

Currently, there are two ways to change properties for APPC Features:
- Permanent Change: In appc.properties, change property values as needed and commit changes in your current git repo where your APPC Deployment code repo is at. Then, run your Jenkins job that deploys the APPC Docker Image (make sure the Jenkins Job configuration points to the branch where you just commited the properties change) to make sure that APPC Docker Image contains latest changes of appc.properties from the beginning (of course, the Host VM where the docker containers will be deployed at needs to update images with "docker-compose pull" to pick up the changes you just committed and compiled).
- Temporary Change (for quick testing/debugging): In the APPC Docker Container, find the appc.properties file in /opt/onap/appc/properties/appc.properties and make changes as needed. Then, restart the APPC Docker Container by running "docker stop <APPC_DOCKER_CONTAINER>" then "docker start <APPC_DOCKER_CONTAINER>")  (NOTE: This approach will lose all changes done in appc.properties if the docker container is destroyed instead of stopped).

# Additional Notes

- For more information on a current list of available properties for APPC Features, please go to README.md located in the installation directory path of the APPC Deployment Code.
- More documentation can be found on the ONAP Wiki's [APPC Documentation Page](https://wiki.onap.org/display/DW/Controllers) and in ONAP's [Read the docs](http://onap.readthedocs.io/en/latest/release/index.html#projects) documentation site.
