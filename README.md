# upday-task

**High Level Outcome**: - Enable us to launch a new microservice(s) in Kubernetes on a highly available and load balanced public cloud environment (eg: AWS) from scratch.

**Problem statemen**t: - Assuming that the highly available and load balanced cloud environment and Kubernetes cluster exists, you are required to automate the deployment pipeline using Jenkins to containerize and deploy the application to Kubernetes. - (Optional) Bonus points, if you are able to automate the highly available and
load balanced cloud environment and Kubernetes cluster creation.

**You are provided with**: - A java microservice application. To run the application, executejava -jar helloworld.jar . The application will be available on TCP port 8080. The application also exposes a healthcheck endpoint at the route /actuator/health . The application can be downloaded from https://updayinterview-test.s3-eu-west-1.amazonaws.com/helloworld.jar .

**What is expected**: - Use of infrastructure as code tools to (eg: Ansible/Terraform/Packer/Pulumi/Jenkinsfile/k8s manifests) to package, deploy and run the application. - We expect a production ready setup. A non-exhaustive list: Ensuring that application is started before it is served with traffic, node affinity/pinning, horizontal pod autoscalers, pod disruption budgets, running applications as non-root, offload TLS at the loadbalancer/ingress. Incorporate at least 4 items in this list, Bonus points, if implementing all the items in the list. - All the scripts, configs, playbooks, manifests etc. in a publicly visible DVCS (eg: GitHub). - A concise README on the Strategy/Architecture along with instructions to recreate the setup.

## Strategy

The task is about to find out answer for the below 4 strategic goals

- [x] Set up an automatic scaling HA infrastructure with kubernetes

- [x] Find out the extra dependencies which may require for the smooth functionality of the application

- [x] Identify and implement a smooth mechanism to build the application image with the help of a better cicd pipeline

- [x] Template the required kubernetes objects for easy deployment

## Overview of the solution

This solution consist of two parts and is organised as two folders:

<details>
    <summary>upday-infra</summary>
    <p>Contains the K8s infra and dependencies</p>
 </details>

The infrastructure part consist of two subfolders - [terraform-iac](https://github.com/jpadmin/upday-task/tree/main/upday-infra/terraform-iac) and [kubernetes-reqs](https://github.com/jpadmin/upday-task/tree/main/upday-infra/kubernetes-reqs).

**terraform-iac** has the infrastructure code for setting up kubernetes cluster written in terraform. It make uses of AWS EKS feature to set up a kubernetes cluster with EC2 servers, that are deployed using AWS Autoscaling groups. These serves as the worker node for the cluster hosting the application workloads. Terraform module includes infrastructure backbone include VPC, Subnet, Route tables, Autoscaling groups, Security groups, EKS cluster components. EC2 worker nodes are set up in a private subnets and has components in public subnet like loadbalancers that expose the required endpoints to public internet. 

**kubernetes-reqs** includes the dependencies that may be required to run the application in the kubernetes cluster. As of now the only dependency we set up is the **metrics server** to calculate the resource accumulation of the pods and nodes, and the application requires these metrics as a factor to when the horizontal pod auto scaling is supposed to scale up or scale down. 

 <details>
    <summary>upday-app</summary>
    <p>CICD pipelines to build the image and kubernetes manifests organised using helm</p>
 </details>

 The application part consist of the two subfolders - [jenkins-job](https://github.com/jpadmin/upday-task/tree/main/upday-app/jenkins-job) and [helm-chart](https://github.com/jpadmin/upday-task/tree/main/upday-app/helm-chart).

 **jenkins-job** consist of the files required to generate the upday-app docker image. The jenkins(shown below) asks for the build agent and docker image parameters to build the image using the Dockerfile and push the it to the docker registry. 

~~~
string(name: 'docker_agent', description: 'Jenkins Build agent with docker utility installed')
string(name: 'docker_url', description: 'Docker registry URL')
string(name: 'docker_organisation_name', description: 'Docker organisation name under which repo is created')
string(name: 'docker_credential_name', description: 'Save docker registry logins in the jenkins credentials and provide the name of jenkins credential here')
string(name: 'docker_repo_name', description: 'Docker repository name used to save the docker image')
~~~

**helm-chart** is the final collection of kubernetes objects that constitutes the upday application. It makes use of kubernetes deployment and service manifests to set up the environment. This deployment is controlled by horizontal pod autoscaling to ensure that the application and the cluster itself is upscaled on event of high resource need or request limits as required by the application. Overall fault tolerance is also maintained using pod disruption budget if in case if the application replicas increases beyond 2.

## How to Deploy the solution

 <details>
    <summary>Setting up Kubernetes cluster</summary>
    <p>Installation of normal EKS cluster</p>
 </details>

 - Install **awscli** and configure it using admin IAM user using [this installation link](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-version.html) and [this configuration link](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).

 - Install **terraform**(preferred version is 1.1.9) using [this installation link](https://learn.hashicorp.com/tutorials/terraform/install-cli).

 - Install **kubectl** using [this installation link](https://kubernetes.io/docs/tasks/tools/).

 - Clone the repository and change to **terraform-iac** folder.
 ~~~
 git clone https://github.com/jpadmin/upday-task.git
 cd upday-task/upday-infra/terraform-iac
 ~~~

 - If there is no S3 bucket for maintaining the terraform state file, please create a new S3 bucket from the AWS S3 console and configure the bucket name and key in the **backend.tf** file.

 - Adjust the region and VPC IP addresses subnets by reviewing the **vpc.tf** file.

 - Adjust the worker groups parameters by reviewing the **eks-cluster.tf** file.

 - Once the parameters are set and finalized, please initialize the terraform project.
 ~~~
 terraform init
 ~~~

 - Once the project is initialized properly, you can run terraform apply and have a final review of the resources to be deployed and type 'yes' once you are okay to deploy the resources displayed for the review. This will deploy all the infra components.
 ~~~
 terraform apply
 ~~~

 - After deploying the cluster and once all the worker nodes are ready from the EKS console in AWS, you can start configuring the kubeconfig on your terminal by running the below command.
 ~~~
 aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)
 ~~~

 - Now verify if you are able to connect to the cluster by running the below command.
 ~~~
 kubectl get no
 ~~~

 <details>
    <summary>Covering the dependencies - Metric Server</summary>
    <p>Installation of Metric server</p>
 </details>

 - Clone the repository(if not already done) and change to **kubernetes-reqs** folder.
 ~~~
 git clone https://github.com/jpadmin/upday-task.git
 cd upday-task/upday-infra/kubernetes-reqs
 ~~~

 - Install it using the official manifest file.
 ~~~
 kubectl apply -f metric-server.yaml
 ~~~

 <details>
    <summary>Setting the Jenkins job</summary>
    <p>CICD pipeline</p>
 </details>

 - Configure the jenkins job using the declarative groovy script in **upday-task/upday-app/jenkins-job/Jenkinsfile**.

 - Provide the inputs as given below and run the job to create the docker image for the upday-app application.
 ~~~
 string(name: 'docker_agent', description: 'Jenkins Build agent with docker utility installed')
 string(name: 'docker_url', description: 'Docker registry URL')
 string(name: 'docker_organisation_name', description: 'Docker organisation name under which repo is created')
 string(name: 'docker_credential_name', description: 'Save docker registry logins in the jenkins credentials and provide the name of jenkins credential here')
 string(name: 'docker_repo_name', description: 'Docker repository name used to save the docker image')
 ~~~

 <details>
    <summary>Packaging and deploying the application</summary>
    <p>Helm part of the solution</p>
 </details>

 - Install helm (preferrably v3.5.2) using [this installation link](https://helm.sh/docs/intro/install/).

 - Clone the repository(if not already done) and change to **helm-chart** folder.
 ~~~
 git clone https://github.com/jpadmin/upday-task.git
 cd upday-task/upday-app/helm-chart
 ~~~

 - Review the **values.yaml** and update the image section with the name of the docker image created from jenkins-job if necessary. Right now I have created a docker image in docker hub with the name **jpadmin/upday-app** and configured it in there. Also you need to replace value for the service.beta.kubernetes.io/aws-load-balancer-ssl-cert with arn of the SSL certificate you wanted to use for the application URL. 

 - Package your helm chart for deployment using the below command.
 ~~~
 cd upday-task/upday-app
 helm package helm-chart
 ~~~

 - Finally install the helm package to the cluster by running the command.
 ~~~
 cd upday-task/upday-app
 helm install spring-boot helm-chart
 ~~~

 - After the application is deployed successfully run the below command to get the ELB http endpoint.
 ~~~
 kubectl get svc spring-boot-upday-app -o json | jq -r ".status.loadBalancer.ingress[0].hostname"
 ~~~

 ## Live Test and URL

~~~
$ # Here I am going to upday-app folder
$ cd upday-task/upday-app

$ # Packaging the helm chart
$ helm package helm-chart
Successfully packaged chart and saved it to: upday-app-0.1.0.tgz

$ # Installing it to my cluster
$ helm install spring-boot upday-app-0.1.0.tgz
NAME: spring-boot
LAST DEPLOYED: Thu Apr 28 11:04:43 2022
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None

$ # Getting the AWS ELB endpoint for the app
$ kubectl get svc spring-boot-upday-app -o json | jq -r ".status.loadBalancer.ingress[0].hostname"
ab0f89e050ba34b21bd91e89edb3e982-465562442.us-east-1.elb.amazonaws.com

$ # Now I wait for sometime until my application pods are in ready state
$ kubectl get po -w
NAME                                     READY   STATUS    RESTARTS   AGE
spring-boot-upday-app-7c788f7c5d-52rxn   0/1     Running   0          45s
spring-boot-upday-app-7c788f7c5d-qh8lx   0/1     Running   0          60s
spring-boot-upday-app-7c788f7c5d-wc52m   0/1     Running   0          45s

$ # Calling the app url and it works fine
$ curl -i http://ab0f89e050ba34b21bd91e89edb3e982-465562442.us-east-1.elb.amazonaws.com
HTTP/1.1 200 OK
Content-Type: text/plain;charset=UTF-8
Content-Length: 23

Hello World from upday!


$ # Calling the app url using https and with k flag for it is self signed

$ curl -ki https://ab0f89e050ba34b21bd91e89edb3e982-465562442.us-east-1.elb.amazonaws.com
HTTP/1.1 200 OK
Content-Type: text/plain;charset=UTF-8
Content-Length: 23
Connection: keep-alive

Hello World from upday!

~~~

## Evaluation Checklist

- [x] Ensuring that application is started before it is served with traffic
- [x] Node affinity/pinning
- [x] Horizontal pod autoscalers
- [x] Pod disruption budgets
- [x] Running applications as non-root
- [x] Offload TLS at the loadbalancer/ingress.