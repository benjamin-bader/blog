#!/bin/bash

hugo -d out/
rsync -avz -e "ssh -i /home/ben/.ssh/ben_azure -o StrictHostKeyChecking=no" out/ bendb.cloudapp.net:/home/ben/www