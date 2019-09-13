# survivorship
#A project on python which uses Terraform for high durability on AWS infrastructure



Here, I created a Lambda function written on Python. It will be triggered whenever one of the EC2 instances
(can be specified in the Cloudwatch event) is terminated. Once the trigger accesses the function, it will deploy an architecture ( in my case, this is a VPC with a specific number of subnets, route tables, security groups. Also, Terraform will find a latest snapshot on a separate S3 ( using a specific tag), create an AMI of it and deploy the new EC2 instances in a new region using this AMI. The EC2 instances will be deployed in an Autoscaling group behind an ELB and the group will use a golden configurations).

#In order to get all that working, do not forget to:

- make sure that the Lambda function has an appropriate Execution role (  AmazonS3FullAccess, AmazonVPCFullAccess,  AmazonDMSVPCManagementRole). Feel free to create your own one using your own policies.
- Lambda has enough execution time and memory in the Basic settings
- have a Terraform file as well as a Shell one (in my case, it is used for "user_data" in Launch Configuration) on a specified S3 bucket.
- change some of the parameters in current files to your own ones (e.g region, BUCKET_NAME, IDs of EC2 instances for event trigger and so on)
