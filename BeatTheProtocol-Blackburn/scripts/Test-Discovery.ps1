# Quick test: listen for StagelinQ discovery broadcasts on UDP 51337
# Run this while the Prime Go+ is on the same network

$port = 51337
$udpClient = [System.Net.Sockets.UdpClient]::new($port)

try {
    Write-Host "Listening for StagelinQ discovery on UDP port $port..."
    Write-Host "Press Ctrl+C to stop.`n"

    $endpoint = [System.Net.IPEndPoint]::new([System.Net.IPAddress]::Any, 0)

    while ($true) {
        $bytes = $udpClient.Receive([ref]$endpoint)
        $magic = [System.Text.Encoding]::ASCII.GetString($bytes, 0, 4)
        Write-Host "Received $($bytes.Length) bytes from $($endpoint.Address) (magic: $magic)"
    }
}
finally {
    $udpClient.Close()
}
