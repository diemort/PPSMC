#!/bin/bash

# clean error logs:
for i in `ls ./err`; do rm -rf ./err/${i}/*; done
rm -rf ./err/*.out
rm -rf ./err/*.err
# clean dag logs:
rm -rf *.dag.*
