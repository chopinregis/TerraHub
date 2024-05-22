   locals {

     vm_config = yamldecode(file("${path.module}/configs/vm_config.yaml"))["vm_settings"][0]  # Access the first element in the list

     common_tags = {
       ManagedBy = "Terraform"
       Environment = "Dev"
     }
   }
   
