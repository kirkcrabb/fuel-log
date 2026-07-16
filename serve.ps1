# Fuel Log: serve this folder for local verification (used by Claude)
param([int]$Port = 8750)
Set-Location $PSScriptRoot
Start-Process python -ArgumentList "-m","http.server",$Port -WindowStyle Hidden
Start-Sleep 2
"serving http://localhost:$Port/"
