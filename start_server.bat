@echo off
title Anniversary Localhost Server
echo Starting server on http://localhost:8080 ...
powershell -ExecutionPolicy Bypass -File "%~dp0serve.ps1"
pause

