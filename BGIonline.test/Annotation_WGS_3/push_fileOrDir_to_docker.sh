#!/bin/bash
file=$1
id=$2
tar -cv $file | docker exec -i $id tar x -C /var/data

