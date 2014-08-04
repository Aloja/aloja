#!/bin/bash
sudo cp .travis_nginx.conf /etc/nginx/nginx.conf
sudo service nginx restart
