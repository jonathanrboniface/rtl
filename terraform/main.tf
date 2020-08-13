provider "google" {
  #  credentials = file("../accounts.json")
  project = var.project
}

data "google_client_config" "current" {
}

resource "google_container_registry" "registry" {
}

data "google_container_registry_image" "default" {
  name = var.name
  tag  = "latest"
}

resource "google_storage_bucket_iam_member" "viewer" {
  bucket = google_container_registry.registry.id
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.service_account}"
}
/*

Configure VPN Server and firewall rules to route GKE Ingress through for increased security

Identify and add requirements for lstio service mesh before creating the cluster if necessary 

Explicitly Assign roles to service account and users where necessary to ensure all can access

*/

resource "google_container_cluster" "primary" {
  name                     = "my-vpc-native-cluster"
  location                 = var.location
  project                  = var.project
  remove_default_node_pool = true
  initial_node_count       = 1

  node_config {
    service_account = var.service_account
  }
  network    = "default"
  subnetwork = "default"

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "/16"
    services_ipv4_cidr_block = "/22"
  }

}

resource "google_container_node_pool" "primary" {
  name       = "my-node-pool"
  location   = "us-central1"
  project    = var.project
  cluster    = google_container_cluster.primary.name
  node_count = 1
  #  


  node_config {
    service_account = var.service_account
    oauth_scopes = [
      /*
      TO DO - Research into each of the below to determine if it is required to conform to least privileged access
    */
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      env = var.project
    }

    # preemptible  = true
    machine_type = "n1-standard-1"
    disk_size_gb = 10
    tags         = ["gke-node", "${var.project}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
  depends_on = [google_container_cluster.primary]
}


output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}


resource "google_cloudbuild_trigger" "rlt-test" {
  trigger_template {
    branch_name = "master"
    repo_name   = var.name
  }
  project = var.project


  /* TO DO 
  further notes in ../application/rlt-test/cloudbuild.yaml
  
  include google_cloudbuild_trigger build steps directly within terraform
  rather than referencing an alternative file and deploy through tiller and helm


  helm package ./
  helm repo index rtl-test-charts --url https://console.cloud.google.com/storage/browser/rtl-test-gcs
  gsutil rsync -d ./rtl-test-charts gs://rtl-test-gcs

  */


  #  substitutions = {
  #    PROJECT_ID = var.project
  #  }

  # build {
  #   steps:
  # # build the container image
  #   - name: "gcr.io/cloud-builders/docker"
  #     args: ["build", "-t", "gcr.io/$PROJECT_ID/rlt-test:latest", "."]
  # # push container image
  #   - name: "gcr.io/cloud-builders/docker"
  #     args: ["push", "gcr.io/$PROJECT_ID/rlt-test:latest"]
  # # deploy container image to GKE
  #   - name: "gcr.io/cloud-builders/gke-deploy"
  #     args:
  #     - run
  #     - --filename=kubeconfig.yaml
  #     - --image=gcr.io/$PROJECT_ID/rlt-test:latest
  #     - --location=us-central1
  #     - --cluster=my-vpc-native-cluster
  # }

  filename   = "../application/${var.name}/cloudbuild.yaml"
  depends_on = [google_container_cluster.primary, google_container_node_pool.primary, google_storage_bucket_iam_member.viewer]
}









