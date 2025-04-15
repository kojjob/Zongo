#!/bin/bash
echo "Stopping any running Rails server..."
pkill -f "rails server" || true
echo "Starting Rails server..."
bundle exec rails server -p 3000
