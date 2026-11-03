@echo off
rem Double-click to start the game: runs a local web server on 127.0.0.1 and opens Edge / Chrome.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve.ps1" %*
