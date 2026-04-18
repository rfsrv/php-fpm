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

variable "WPCLI_VERSION" {
  default = "2.11.0"
}

variable "SUPERCRONIC_VERSION" {
  default = "0.2.33"
}

group "default" {
  targets = ["php83", "wordpress83"]
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

target "wordpress83" {
  context    = "./wordpress"
  dockerfile = "Dockerfile"
  # Use the locally-built php83 target as the base image so CI doesn't need
  # to push/pull the base before building this variant.
  contexts = {
    "ghcr.io/rfsrv/php-fpm:8.3" = "target:php83"
  }
  args = {
    PHP_VERSION         = PHP_VERSION
    WPCLI_VERSION       = WPCLI_VERSION
    SUPERCRONIC_VERSION = SUPERCRONIC_VERSION
  }
  tags = [
    "${REGISTRY}/php-wordpress:8.3",
    "${REGISTRY}/php-wordpress:latest",
  ]
  cache-from = ["type=registry,ref=${REGISTRY}/php-wordpress:cache-8.3"]
  cache-to   = ["type=registry,ref=${REGISTRY}/php-wordpress:cache-8.3,mode=max"]
  platforms  = ["linux/amd64", "linux/arm64"]
}
