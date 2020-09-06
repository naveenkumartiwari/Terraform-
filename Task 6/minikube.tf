provider "kubernetes" {
  config_context_cluster   = "minikube"
}

resource "null_resource" "minikube_launch"{

    provisioner "local_exec" {
    
    command = "minikube start" 
       
    }
}




resource "kubernetes_deployment" "wordpress" {
  metadata {
    name = "wordpress_site"
    labels = {
      env = "testing"
    }
  }


  spec {
    replicas = 2


    selector {
      match_labels = {
        env = "testing"
      }
    }


    template {
      metadata {
        labels = {
          env = "testing"
        }
      }


      spec {
        container {
          image = "wordpress"
          name  = "my_wordpress_site"
        }
      }
    }
  }
}



resource "kubernetes_service" "kube_Service" {
  metadata {
    name = "kubeservice"
  }
  spec {
    selector = {
      env = kubernetes_pod.wordpress.metadata.0.labels.env
    }
    port {
      node_port   = 32000 
      port        = 80
      target_port = 80
    }
    type = "NodePort"
  }
}


resource "null_resource" "minikube_wordpress_url" {
 provisioner "local-exec" {
  command = "minikube ip"
 }

}

