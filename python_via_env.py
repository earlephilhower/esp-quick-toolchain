#!/usr/bin/env python3
import os
import sys

EXE = os.environ.get("ESP8266_ARDUINO_PYTHON_PATH", "python3")
ARG = ["env", EXE] + sys.argv[1:]

os.execv("/usr/bin/env", ARG)
