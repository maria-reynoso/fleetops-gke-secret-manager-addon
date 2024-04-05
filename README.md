# fleetops-gke-secret-manager-addon

Using Secret Manager addon for GKE

## Requirments:
- Create your Venafi as a [Service account](https://vaas.venafi.com/jetstack) and copy the API key from your user preferences.

## Deploy cluster with secret manager addon enabled

```sh
CLUSTER_NAME="fleetops"
gcloud beta container clusters create $CLUSTER_NAME \
    --enable-secret-manager \
    --location=europe-west2-a \
    --cluster-version=1.29 \
    --workload-pool=jetstack-maria.svc.id.goog
```

Retrieve credentials:

```sh
gcloud container clusters get-credentials $CLUSTER_NAME
```

## Create secret in Secret Manager 

```sh
SECRET_NAME="alertmanager-config"
gcloud secrets create $SECRET_NAME \
    --replication-policy="automatic"
```

```sh
FILE_NAME="alertmanager/alertmanager-config.yaml"
gcloud secrets versions add $SECRET_NAME --data-file=$FILE_NAME
```

## Grant access

Create alertmanager service account and bind the IAM service account to the service account

```sh
kubectl apply -f service-account.yaml

gcloud iam service-accounts add-iam-policy-binding \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:jetstack-maria.svc.id.goog[monitoring/alertmanager-secret-sa]" \
    fleetops@jetstack-maria.iam.gserviceaccount.com
```

Grant the IAM service account permission to access the secret

To grant the service account permission to access the secret, run the following command:

```sh
gcloud secrets add-iam-policy-binding $SECRET_NAME \
    --member=serviceAccount:fleetops@jetstack-maria.iam.gserviceaccount.com \
    --role=roles/secretmanager.secretAccessor
```

## Create SecretProviderClass

Create monitoring namespace

```sh
kubectl create namespace monitoring
```

Deploy `SecretProviderClass`:

```sh
kubectl apply -f deploy/manifests/app-secrets.yaml
```

## Deploy Prometheus and Alertmanager

Deploy prometheus:

```sh
make deploy_prometheus
```

With the help of kubectl port-forwarding, we can directly connect to a pod on a specific port from our workstation to container port. Run following commands to connect to a pod through browser.

```sh
#to get the pod name, run below command
kubectl get pods –namespace=monitoring
NAME                               READY     STATUS    RESTARTS   AGE
prometheus-monitoring-xxxx   1/1       Running   0          1m

#run below command to open port on 8080
kubectl port-forward prometheus-monitoring-xxxx 8080:9090 -n monitoring
```

Now from browser you can access Prometheus console by using url: http://localhost:8080

Deploy Alertmanager

```sh
make deploy_alertmanager
```

## Cleanup

```sh
make cleanup
```
