   locals {

     vm_config = yamldecode(file("${path.module}/configs/vm_config.yaml"))["vm_settings"]

     common_tags = {
       ManagedBy = "Terraform"
       Environment = "Dev"
     }
   }
   
