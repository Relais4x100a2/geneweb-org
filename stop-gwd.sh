#!/bin/bash
# Script pour arrêter le serveur GeneWeb

pkill -f "gwd.exe.*-hd hd -bd bdds -p 8080"
echo "Serveur GeneWeb arrêté"

