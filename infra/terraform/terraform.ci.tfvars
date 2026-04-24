vpc_id = "vpc-0f686b508e3fef6ea"

private_subnets = [
  "subnet-0f15bf0504c9be76f",
  "subnet-03c63fb99d0e54a5b",
]

public_subnets = [
  "subnet-0a901e50d0889a1dc",
  "subnet-0c3fa5ef5c77e6596",
  "subnet-0ead1af7a12a686c8"
]

ecr_image_uri = "121023050297.dkr.ecr.us-east-1.amazonaws.com/aspnet-api-production:latest"

image_uri = "121023050297.dkr.ecr.us-east-1.amazonaws.com/aspnet-api-production:latest"
api_key              = "ci-dummy"
db_connection_string = "Server=ci;Database=ci;"
