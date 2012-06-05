#!/bin/bash
ps aux | grep java | grep jboss | grep standalone | sed 's/^[^ ]*[ ]* \([0-9]*\).*/\1/'
