@echo off
cd /d D:\demo
start http://localhost:8080/index.html
python -m http.server 8080
