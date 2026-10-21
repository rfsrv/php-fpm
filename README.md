# php-fpm

Minimal multi-arch PHP-FPM base image for WordPress-style workloads.

## Included

- PHP 8.3 on Alpine (`php:8.3-fpm-alpine`), minimum 8.3.36
- Composer 2
- Extensions: `bcmath`, `exif`, `gd`, `intl`, `mbstring`, `mysqli`, `opcache`, `pdo_mysql`, `zip`, `imagick`, `redis`
- FPM health endpoints: `/ping` and `/status`

## Local build

```bash
docker buildx bake
```

Builds always pull current upstream images and fail if PHP is older than 8.3.36,
which fixes CVE-2026-109618 and CVE-2026-109619. Both `php-fpm:8.3` and
`php-wordpress:8.3` are built together, with the WordPress variant consuming the
newly built PHP-FPM base.

After publishing these bases, rebuild downstream application images with
`--pull` and deploy the new images to replace both PHP-FPM and cron containers.
Restarting containers with an old application image does not update PHP.

## Override extension versions

```bash
docker buildx bake --set *.args.PHPREDIS_VERSION=6.3.0 --set *.args.IMAGICK_VERSION=3.8.1
```
