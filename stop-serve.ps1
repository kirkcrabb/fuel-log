# Fuel Log: stop any python http.server started by serve.ps1
Get-CimInstance Win32_Process -Filter "Name='python.exe'" |
  Where-Object { $_.CommandLine -match 'http\.server' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -Confirm:$false }
"stopped"
