variable "REGISTRY" {
  default = "ghcr.io/rfsrv"
}

variable "IMAGE_NAME" {
  default = "php-fpm"
}

variable "PHP_VERSION" {
  default = "8.3"
}

variable "PHPREDIS_VERSION" {
  default = "6.3.0"
}

variable "IMAGICK_VERSION" {
  default = "3.8.1"
}

group "default" {
  targets = ["php83"]
}

target "php83" {
  context    = "."
  dockerfile = "Dockerfile"
  args = {
    PHP_VERSION      = PHP_VERSION
    PHPREDIS_VERSION = PHPREDIS_VERSION
    IMAGICK_VERSION  = IMAGICK_VERSION
  }
  tags = [
    "${REGISTRY}/${IMAGE_NAME}:8.3",
    "${REGISTRY}/${IMAGE_NAME}:latest",
  ]
  cache-from = ["type=registry,ref=${REGISTRY}/${IMAGE_NAME}:cache-8.3"]
  cache-to   = ["type=registry,ref=${REGISTRY}/${IMAGE_NAME}:cache-8.3,mode=max"]
  platforms  = ["linux/amd64", "linux/arm64"]
}
