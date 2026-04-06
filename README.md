# php-fpm

Minimal multi-arch PHP-FPM base image for WordPress-style workloads.

## Included

- PHP 8.3 on Alpine (`php:8.3-fpm-alpine`)
- Composer 2
- Extensions: `bcmath`, `exif`, `gd`, `intl`, `mbstring`, `mysqli`, `opcache`, `pdo_mysql`, `zip`, `imagick`, `redis`
- FPM health endpoints: `/ping` and `/status`

## Local build

```bash
docker buildx bake
```

## Override extension versions

```bash
docker buildx bake --set *.args.PHPREDIS_VERSION=6.3.0 --set *.args.IMAGICK_VERSION=3.8.1
```
