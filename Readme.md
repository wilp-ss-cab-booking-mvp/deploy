# SS Cab Booking MVP

This project is a microservices-based cab booking system deployed on a Kubernetes cluster using Helm. It includes the following services:

- **User Service**: Handles user registration and authentication.
- **Driver Service**: Manages driver registration and availability.
- **Booking Service**: Handles cab bookings.
- **Payment Service**: Processes payments for bookings.


## Pre-requisite
Install choco (package manager for windows) </br>
To install refer - https://chocolatey.org/install </br>
Note: Make sure to run the choco install commands on a poweshell window with admin access.

- git bash: Install it from https://git-scm.com
- docker: Install docker desktop from https://www.docker.com/
- kind cli: `choco install make`
- kubectl: `choco install kubectl`
- helm: `choco install helm`
- make: `choco install make`


## Commands
### Build Services
This command clones the repositories for all services, builds Docker images, and saves them locally.
```bash
make build
```

### Setup and configure the cluster
This command sets up a Kind (Kubernetes in Docker) cluster, installs the metrics server, ingress controller, and loads the Docker images into the cluster.
```bash
make setup
```

### Deploy services
This command deploys all services to the Kubernetes cluster using Helm.
```bash
make deploy
```

### Clean Up
This command removes all cloned repositories, Docker images, and deletes the Kind cluster.
```bash
make clean
```

### Destroy Cluster
This command destoys the kind cluster
```bash
make destroy
```

## Accessing the service
```bash
# user service
curl -H "Host: user.ss-cab-booking.local" http://localhost:30000
# booking service
curl -H "Host: booking.ss-cab-booking.local" http://localhost:30000
# driver service
curl -H "Host: driver.ss-cab-booking.local" http://localhost:30000
# payment service
curl -H "Host: payment.ss-cab-booking.local" http://localhost:30000

```
