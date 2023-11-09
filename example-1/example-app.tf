resource "kubernetes_namespace" "app" {
  metadata {
    annotations = {
      name = "app"
    }

    name = "app"
  }
}

resource "kubernetes_service" "service" {
  metadata {
    name      = "example-service"
    namespace = kubernetes_namespace.app.id
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "external"
      "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "ip"
      "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
    }
  }
  spec {
    port {
      port = 80
    }
    selector = {
      app = kubernetes_deployment.nginx-deployment.metadata.0.labels.app
    }
    load_balancer_class = "service.k8s.aws/nlb"
    type                = "LoadBalancer"
  }
}


resource "kubernetes_deployment" "nginx-deployment" {
  metadata {
    name      = "example-nginx"
    namespace = kubernetes_namespace.app.id
    labels    = {
      app = "example-nginx"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "example-nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "example-nginx"
        }
      }

      spec {
        container {
          image = "nginx:1.25.3-alpine3.18-slim"
          name  = "example-nginx"
          resources {
            limits = {
              cpu    = "250m"
              memory = "50Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}
