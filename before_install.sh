#!/bin/bash

# Check if 'index.html' exists in the deployment target directory (/var/www/html/)
if [ -f /var/www/html/index.html ]; then
    # Remove the existing index.html file
    rm /var/www/html/index.html
    echo "Existing index.html file removed"
fi

# Proceed with deployment
exit 0

