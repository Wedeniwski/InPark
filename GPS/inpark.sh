#!/bin/sh
java -cp GPS/GPS.jar PListDownload
java -Xmx500M -cp GPS/GPS.jar WaitingTimesCrawler | tee -a inpark.log
