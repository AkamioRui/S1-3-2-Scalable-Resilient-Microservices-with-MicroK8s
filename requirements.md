# Application Design & Image Workflow
Develop or adapt a stateless web application (e.g., a REST API, a web scraper, or a task processor).
Create optimized Dockerfiles for your services.
Workflow: You must push your images to your local registry and configure MicroK8s to pull from this registry (rather than public Docker Hub).

*Registry Proof: Show the image residing in your local registry and the K8s manifest pointing to it.*

2. Horizontal Scaling
Configure your application to run with multiple replicas.

Implement a Horizontal Pod Autoscaler (HPA) based on CPU/Memory metrics (or demonstrate manual scaling via the CLI).


*Scaling Demo: Increase the load (or use a command) to trigger the creation of additional replicas and show them joining the cluster.*


3. Self-Healing Architecture
Define Liveness and Readiness probes in your Kubernetes manifests.

The system must automatically detect and restart failed container instances without human intervention.

*The "Chaos" Test: Manually delete a running Pod during the demo. Prove that the service remains reachable and that K8s automatically spawns a replacement.*


4. Ingress & Load Balancing
Configure an Ingress Resource to route external traffic to your service.

Demonstrate that the Ingress controller effectively distributes traffic across your multiple pod replicas.

*Traffic Visualization: Run a simple loop (e.g., a curl script) to show traffic hitting different Pod IPs/Hostnames via the Ingress.*


5. Resource Constraints (for low-end hardware)
*Define resources: limits and requests in your YAML to ensure the system remains stable on your specific hardware.*