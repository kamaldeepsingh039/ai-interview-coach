#!/bin/bash
sed -i "s|__APP_ALB_DNS__|${internal_alb_dns}|g" /etc/nginx/nginx.conf
systemctl restart nginx