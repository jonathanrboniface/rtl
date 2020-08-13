provider "kubernetes" {
  version = "~> 1.10.0"
  host    = google_container_cluster.primary.endpoint
  token   = data.google_client_config.current.access_token
  client_certificate = base64decode(
    google_container_cluster.primary.master_auth[0].client_certificate,
  )
  client_key = base64decode(google_container_cluster.primary.master_auth[0].client_key)
  cluster_ca_certificate = base64decode(
    google_container_cluster.primary.master_auth[0].cluster_ca_certificate,
  )
}

resource "kubernetes_namespace" "staging" {
  metadata {
    name = "staging"
  }
}

resource "google_compute_address" "default" {
  name   = var.network_name
  region = var.region
}



resource "kubernetes_deployment" "rlt-test" {
  metadata {
    name = var.name
    labels = {
      App = var.name
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        App = var.name
      }
    }
    template {
      metadata {
        labels = {
          App = var.name
        }
      }
      spec {
        container {
          #  image = "nginx:1.7.8"
          image = "gcr.io/elasticsearch-236916/rlt-test:latest"
          name  = var.name

          port {
            container_port = 80
          }

          resources {
            limits {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
  depends_on = [
    google_container_cluster.primary,
    google_container_node_pool.primary,
    kubernetes_namespace.staging,
    google_compute_address.default
  ]

}

resource "kubernetes_service" "rlt-test" {
  metadata {
    name = var.name
  }
  spec {
    selector = {
      App = kubernetes_deployment.rlt-test.spec.0.template.0.metadata[0].labels.App
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
  depends_on = [
    google_container_cluster.primary,
    google_container_node_pool.primary,
    kubernetes_namespace.staging,
    google_compute_address.default,
    kubernetes_deployment.rlt-test
  ]

}

output "lb_ip" {
  value = kubernetes_service.rlt-test.load_balancer_ingress[0].ip
}

/* TO DO


 Create kubernetes_ingress to handle multiple deployments to diffirent end points.
 Using variables to construct and define the enviroments.
 If the aim is to use this for multiple clients the naming convention could be altered to the below:

  ${var.client}-${var.name}-${var.env}

 Create stackdriver monitoring alert policies, dashboards and notifications based on the end points
 
# resource "kubernetes_ingress" "example_ingress" {
#   metadata {
#     name = "example-ingress"
#   }

#   spec {
#     backend {
#       service_name = "${var.name}-${var.env}"
#       service_port = 80
#     }

#     rule {
#       http {
#         path {
#           backend {
#             service_name = "${var.name}-${var.env}"
#             service_port = 80
#           }

#           path = "/${var.name}/*"
#         }
#       }
#     }

#     tls {
#       secret_name = "tls-secret"
#     }
#   }
# }
*/


