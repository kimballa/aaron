#!/usr/bin/env bash
# Start Colima with the standard local development resources if it is stopped.

if colima status >/dev/null 2>&1; then
  exit 0
fi

exec colima start --cpu 4 --memory 8 --disk 60
