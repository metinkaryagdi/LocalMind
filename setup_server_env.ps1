# LocalMind Server Environment Setup Script
# Run this script as Administrator on the SERVER MACHINE (2. PC - 192.168.1.50)

Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "      LocalMind - Server Environment Setup          " -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

# 1. Set Environment Variable for Ollama to listen on all interfaces
Write-Host "`n[1/3] Setting OLLAMA_HOST environment variable to 0.0.0.0:11434..." -ForegroundColor Yellow
[System.Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0:11434", [System.EnvironmentVariableTarget]::Machine)
$env:OLLAMA_HOST = "0.0.0.0:11434"
Write-Host "OLLAMA_HOST set to 0.0.0.0:11434 (Global)" -ForegroundColor Green

# 2. Add Windows Firewall Rule for Ollama (Port 11434)
Write-Host "`n[2/3] Configuring Firewall for Ollama Port 11434..." -ForegroundColor Yellow
try {
    netsh advfirewall firewall delete rule name="Ollama LAN Port 11434" | Out-Null
    netsh advfirewall firewall add rule name="Ollama LAN Port 11434" dir=in action=allow protocol=TCP localport=11434 profile=any
    Write-Host "Firewall rule added: Port 11434 is OPEN for LAN inbound traffic." -ForegroundColor Green
} catch {
    Write-Host "Error configuring firewall rule for port 11434: $_" -ForegroundColor Red
}

# 3. Add Windows Firewall Rule for .NET API (Port 5000)
Write-Host "`n[3/3] Configuring Firewall for LocalMind API Port 5000..." -ForegroundColor Yellow
try {
    netsh advfirewall firewall delete rule name="LocalMind Web API Port 5000" | Out-Null
    netsh advfirewall firewall add rule name="LocalMind Web API Port 5000" dir=in action=allow protocol=TCP localport=5000 profile=any
    Write-Host "Firewall rule added: Port 5000 is OPEN for LAN inbound traffic." -ForegroundColor Green
} catch {
    Write-Host "Error configuring firewall rule for port 5000: $_" -ForegroundColor Red
}

Write-Host "`n=====================================================" -ForegroundColor Cyan
Write-Host "Setup Completed! Please restart Ollama service or terminal." -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Cyan
