# build will clone 4 repoisitory and build them
# repositories are: 
# 1.https://github.com/wilp-ss-cab-booking-mvp/user-service.git
# 2.https://github.com/wilp-ss-cab-booking-mvp/driver-service.git
# 3.https://github.com/wilp-ss-cab-booking-mvp/booking-service.git
# 4.https://github.com/wilp-ss-cab-booking-mvp/payment-service.git

PATCH_FILE=./metrics-server-patch.yaml

build:
	@echo "Building user-service..."
	git clone https://github.com/wilp-ss-cab-booking-mvp/user-service
	cd user-service && docker build -t user-service .
	@echo "Building driver-service..."
	git clone https://github.com/wilp-ss-cab-booking-mvp/driver-service.git
	cd driver-service && docker build -t driver-service .
	@echo "Building booking-service..."
	git clone https://github.com/wilp-ss-cab-booking-mvp/booking-service.git
	cd booking-service && docker build -t booking-service .
	@echo "Building payment-service..."
	git clone https://github.com/wilp-ss-cab-booking-mvp/payment-service.git
	cd payment-service && docker build -t payment-service .
	@echo "Building postgres..."
	cd manifests && docker build -t postgres:15 -f ./Dockerfile.postgres .
	@echo "Building busybox..."
	cd manifests && docker build -t busybox:latest -f ./Dockerfile.busybox .
	@echo "All services built successfully!"

	mkdir -p images
	docker save user-service -o images/user-service.tar
	docker save driver-service -o images/driver-service.tar
	docker save booking-service -o images/booking-service.tar
	docker save payment-service -o images/payment-service.tar
	docker save postgres:15 -o images/postgres.tar
	docker save busybox:latest -o images/busybox.tar
	@echo "Images saved to images directory"

# setup will run a kind k8s cluster in the docker.
setup:
	@echo "Setting up kind cluster..."
	kind create cluster --name ss-cab-booking-mvp --config kind-config.yaml
	@echo "Kind cluster setup successfully!"
	kind get kubeconfig --name ss-cab-booking-mvp > kubeconfig.yaml
	@echo "Kubeconfig saved to kubeconfig.yaml"

	@echo "Setting up metrics server"
	kubectl --kubeconfig ./kubeconfig.yaml apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.5.0/components.yaml
	kubectl --kubeconfig ./kubeconfig.yaml patch deployment metrics-server -n kube-system --patch "$$(cat $(PATCH_FILE))"
	@echo "Metrics server setup successfully!"

	@echo "Setting up ingress controller..."
	kubectl --kubeconfig ./kubeconfig.yaml label node ss-cab-booking-mvp-control-plane ingress-ready=true
	kubectl --kubeconfig ./kubeconfig.yaml apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
	kubectl patch svc ingress-nginx-controller -n ingress-nginx \
		--type='merge' \
  		-p '{"spec": {"ports": [{"name": "http","nodePort": 30000,"port": 80,"protocol": "TCP","targetPort": 80}, {"name": "https","nodePort": 30001,"port": 443,"protocol": "TCP","targetPort": 443}]}}'

	@echo "Ingress controller setup successfully!"

	sleep 60

	@echo "Loading images into kind cluster..."
	kind --name ss-cab-booking-mvp load image-archive images/user-service.tar
	kind --name ss-cab-booking-mvp load image-archive images/driver-service.tar
	kind --name ss-cab-booking-mvp load image-archive images/booking-service.tar
	kind --name ss-cab-booking-mvp load image-archive images/payment-service.tar
	kind --name ss-cab-booking-mvp load image-archive images/postgres.tar
	kind --name ss-cab-booking-mvp load image-archive images/busybox.tar
	@echo "All images loaded into kind cluster successfully!"

destroy:
	@echo "Destroying kind cluster..."
	kind delete cluster --name ss-cab-booking-mvp
	rm -f kubeconfig.yaml

deploy:
	helm upgrade --install cab-booking --kubeconfig kubeconfig.yaml --namespace ss --create-namespace ./helm/ss-cab-booking

clean:
	@echo "Cleaning up..."
	rm -rf user-service driver-service booking-service payment-service
	rm -rf images
	@echo "All services cleaned up successfully!"
	kind delete cluster --name ss-cab-booking-mvp
	rm -f kubeconfig.yaml
	@echo "Kind cluster deleted successfully!"