# build will clone 4 repoisitory and build them
# repositories are: 
# 1.https://github.com/wilp-ss-cab-booking-mvp/user-service.git
# 2.https://github.com/wilp-ss-cab-booking-mvp/driver-service.git
# 3.https://github.com/wilp-ss-cab-booking-mvp/booking-service.git
# 4.https://github.com/wilp-ss-cab-booking-mvp/payment-service.git

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
	cd postgres && docker build -t postgres:15 .
	@echo "All services built successfully!"

# setup will run a kind k8s cluster in the docker.
setup:
	@echo "Setting up kind cluster..."
	kind create cluster --name ss-cab-booking-mvp
	@echo "Kind cluster setup successfully!"
	kind get kubeconfig --name ss-cab-booking-mvp > kubeconfig.yaml
	@echo "Kubeconfig saved to kubeconfig.yaml"

	mkdir -p images
	docker save user-service -o images/user-service.tar
	docker save driver-service -o images/driver-service.tar
	docker save booking-service -o images/booking-service.tar
	docker save payment-service -o images/payment-service.tar
	docker save postgres:15 -o images/postgres.tar
	@echo "Images saved to images directory"

	@echo "Loading images into kind cluster..."
	kind --name ss-cab-booking-mvp load image-archive images/user-service.tar
	kind --name ss-cab-booking-mvp load image-archive images/driver-service.tar
	kind --name ss-cab-booking-mvp load image-archive images/booking-service.tar
	kind --name ss-cab-booking-mvp load image-archive images/payment-service.tar
	kind --name ss-cab-booking-mvp load image-archive images/postgres.tar
	@echo "All images loaded into kind cluster successfully!"


deploy:
	@echo "Deploying user-service..."
	kubectl apply -f user-service/deployment.yaml --kubeconfig kubeconfig.yaml
	@echo "Deploying driver-service..."
	kubectl apply -f driver-service/deployment.yaml --kubeconfig kubeconfig.yaml
	@echo "Deploying booking-service..."
	kubectl apply -f booking-service/deployment.yaml --kubeconfig kubeconfig.yaml
	@echo "Deploying payment-service..."
	kubectl apply -f payment-service/deployment.yaml --kubeconfig kubeconfig.yaml
	@echo "All services deployed successfully!"

clean:
	@echo "Cleaning up..."
	rm -rf user-service driver-service booking-service payment-service
	rm -rf images
	@echo "All services cleaned up successfully!"
	kind delete cluster --name ss-cab-booking-mvp
	rm -f kubeconfig.yaml
	@echo "Kind cluster deleted successfully!"