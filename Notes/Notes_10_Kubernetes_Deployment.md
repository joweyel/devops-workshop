# Section 10 - Depyloying applications with Kubernetes

For deplying container to the created kubernetes cluster there has to be some configuration done. For this the following 4 yaml files are created.

- [**`deployment.yaml`**](../kubernetes/deployment.yaml):
- **Purpose**: Defines a Deployment for managing a set of identical pods.
- **Contents**:
  - **apiVersion**: Version of the Kubernetes API.
    - **kind**: Type of resource (Deployment).
    - **metadata**: Metadata about the Deployment (name, namespace).
    - **spec**: Specification of the desired behavior (replicas, selector, template).
    - **template**: Pod template with container specifications (image, ports, environment variables).

- [**`namespace.yaml`**](../kubernetes/namespace.yaml):
    - **Purpose**: Creates a Namespace to isolate resources.
    - **Contents**:
        - **apiVersion**: Version of the Kubernetes API.
        - **kind**: Type of resource (Namespace).
        - **metadata**: Metadata about the Namespace (name).

- [**`secrets.yaml`**](../kubernetes/secrets.yaml):
    - **Purpose**: Defines a Secret to store sensitive data (e.g., Docker credentials).
    - **Contents**:
        - **apiVersion**: Version of the Kubernetes API.
        - **kind**: Type of resource (Secret).
        - **metadata**: Metadata about the Secret (name, namespace).
        - **data**: Base64 encoded secret data (.dockerconfigjson).
        - **type**: Type of secret (kubernetes.io/dockerconfigjson).

- [**`service.yaml`**](../kubernetes/service.yaml):
    - **Purpose**: Defines a Service to expose the Deployment’s pods.
    - **Contents**:
        - **apiVersion**: Version of the Kubernetes API.
        - **kind**: Type of resource (Service).
        - **metadata**: Metadata about the Service (name, namespace).
        - **spec**: Specification of the desired behavior (type, selector, ports).

To use all the files above the bash-script [deploy.sh](../kubernetes/deploy.sh) is used.


## Running the Kubernetes manifest files

First you have to get the files from the local [kubernetes](../kubernetes/)-folder to the build-server:
```bash
# First: Login to the server

sudo su -
cd /opt/
mkdir kubernetes
# Create the files there
touch deployment.yaml namespace.yaml
# Copy the content to the files with editor of your choice `nano`, `vi` etc.
```
<!-- secrets.yaml service.yaml -->

### namespace
Now you have to apply the `namespace.yaml` with `kubectl`. This will create the namespace, that is specified in the file:
```bash
kubectl apply -f namespace.yaml
```

### deployment
Now, run the deployment script:
```bash
kubectl apply -f deployment.yaml
```

After applying this run the following command:
```bash
kubectl get all -n <your-namespace>
```
You will see that the deployment has failed, because the docker images could not get pulled from the artifactory. The cause is due to insufficient authentication. This can be seen when you call this:
```bash
# Get the NAME of one of the 2 pods in the namespace and use it here (<pod> used as placeholder here)
kubectl describe <pod> -n <your-namespace>
```

### secrets
To resolve the problem, JFrog has to be integrated into the Kubernetes cluster.

1. Go to your JFrog and log in
2. Go to: https://xyz.jfrog.io/ui/admin/management/users  (xyz is your personal name you have given during creation of JFrog account)
3. Create a new user by clicking on `[New user]`
   - Name: `dockercred`
   - Email Address: Same as "main"-account
   - Password: `<your-password>`

Now it's time to log in to jrog with docker:
```bash
docker login https://joweyel01.jfrog.io/

Username: dockercred
Password: 
```

You will get the following results (it works):
```txt
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```
Now generate an encoded value for `~/.docker/config.json`
```bash
cat ~/.docker/config.json | base64 -w0
```
Insert the resuting string into the [`secrets.yaml`](../kubernetes/secrets.yaml#L7) and copy it to the build server in the `/opt/kubernetes` directory.
Now apply the `secrets.yaml` with this:
```bash
kubectl apply -f secrets.yaml
# secret/jfrogcred created

# look at the secrets you currently have
kubectl get secret -n <your-namespace>
```
Next is to delete the currently created pods. Since the `deployment.yaml` has not changed, applying with kubectl will do nothing. This basically forces to re-apply the deployment:
```bash
# Get lis with the pods
kubectl get all -n <your-namespace>

# Delete all the pods in your namespace
kubectl delete <pod1> -n <your-namespace>
kubectl delete <pod2> -n <your-namespace>

# Re-apply the deployment
kubectl apply -f deployment.yaml
```
The status of the pods should now be `RUNNING`.
You will also see that the docker image was successfully pulled when running `kubectl describe <pod-name> -n <your-namespace>`

### service
This is needed to access the application that is being deployed.

```bash
touch service.yaml
# Copy the content to the file

# Apply the service configuration
kubectl apply -f service.yaml
```

There is a slight problem. The port `30082` is not open. To rectify this the port is opened over the AWS ui, however it also can be included in the terraform code.
The security group IS NOT `demo-sg` (which was used before for ansible-, jenkins- and build-server) but the one that container `eks-cluster-sg-*`.

Add the following inbound rule:
- **Type**: Custom TCP
- **Protocol**: TCP
- **Port range**: 30082
- **Source**: Anywher IPv4
- **CIDR**: 0.0.0.0/0
- **Description**: Kubernetes service port

Try to access the service, you can now use the public IPv4 address and the port in the browser.

## Applying all yaml-files
- Previously: Everythin was done with root-user
- Now: using the `ubuntu`-user on the build node

```bash
# Getting the files to the non-root ubuntu user
cd /opt
mv kubernetes/ /home/ubuntu
chown -R ubuntu:ubuntu /home/ubuntu

# Now everything should be owned by the user `ubuntu`
ls -la /home/ubuntu/kubernetes

# Switch to ubuntu user
sudo su - ubuntu
```

There is still a problem when using the non-root user `ubuntu`. The cluster credentials are currently only available for the `root`-user. To rectify the situation you can just copy the eks-cluster credentials into the home-directory of the `ubuntu`-user.
```bash
# IMPORTANT: set the IAM user to have the right to access the cluster resources
aws eks update-kubeconfig --region us-east-1 --name jw-eks-01
```

Now run the following command to see if the `ubuntu`-user has access to the cluster:
```bash
kubectl get all -n jw # n := <your-namespace>
```

The next step is to create the [deploy.sh](../kubernetes/deploy.sh) file. For this, all the configurations that were done by applying the singular yaml-files have to be deleted now. Otherwise it is harder to see if the deploy-script is doing what it schould:
```bash
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
kubectl delete -f secret.yaml
kubectl delete -f namespace.yaml
```

Now make the deploy-script executable and run it:
```bash
chmod +x ~/kubernetes/deploy.sh
./deploy.sh
./deploy.sh 
# Outputs:
#   namespace/jw created
#   secret/jfrogcred created
#   deployment.apps/jw-rtp created
#   service/jw-rtp-service created
```

The deployed code should now be accessible again over the browser using the public IP + port `30082` of one of the 2 nodes.

## Deploying throught Jenkins pipeline instead of mannually
For Jenkins to use the kubernetes manifest-files, you have to copy them to the `tweet-trend` repo that was previously used.

```bash
# Add all the yaml-files
git add deployment.yaml namespace.yaml secrets.yaml service.yaml
# Add the deploy-script in executable state (should have "create mode 100755 deploy.sh")
git add --chmod=+x deploy.sh

git commit -m "added k8s manifest-files"
git push origin main
```

Now add the following stage to the Jenkinsfile in your `tweet-trend` repo:
```groovy
// Kubernetes deployment
stage("Deploy")
{
    steps 
    {
        script
        {
            sh './deploy.sh' 
        }
    }
}
```

Before deployment delete the previously created resources:
```bash
kubectl delete -f service.yaml 
kubectl delete -f secret.yaml 
kubectl delete -f deployment.yaml 
kubectl delete -f namespace.yaml 
```

Then add changes and commit and push them to the repository. This should trigger the Jenkins-Pipelined again and deploy the docker container to the eks cluster.


## Releasing a new version of the app using CI/CD

- Open the file `src/main/java/com/valaxy/demo/controller/RepositoryDetailsController.java` in you `tweet-trend` folder and change the returned string of the `getRepos()` method.
- Then change the version from `2.1.2` to `2.1.3` in: 
  - `pom.xml` 
  - `Jenkinsfile`
  - `Dockerfile`

Commit and push the changes and watch the new release be deployed :)