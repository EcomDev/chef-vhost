#
# PHP-FPM Cookbook - PHP-FPM Chef Cookbook to allow building easily vagrant
# environment
# Copyright (C) 2014 Ivan Chepurnyi <ivan.chepurnyi@ecomdev.org>, EcomDev B.V.
#
# This file is part of PHP-FPM Cookbook.
#
# PHP-FPM Cookbook is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# PHP-FPM Cookbook is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with PHP-FPM Cookbook.  If not, see <http://www.gnu.org/licenses/>.
#
source "https://supermarket.getchef.com"

metadata

cookbook "ecomdev_common", github: 'IvanChepurnyi/chef-ecomdev_common', tag: '0.1.0'
cookbook "nginx"
cookbook "vhost_test", path: 'test/fixtures/vhost_test'
cookbook "php_fpm", github: 'IvanChepurnyi/chef-php_fpm', tag: '0.1.8', group: 'development'