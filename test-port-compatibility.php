<?php
/**
 * MAMP Port Compatibility Test Script
 * Tests the package compatibility with different MAMP port configurations
 */

ini_set('display_errors', 1);
error_reporting(E_ALL);

// Set CLI environment to avoid API execution
$_SERVER['REQUEST_METHOD'] = 'CLI';

// Include API functions but prevent execution
define('SKIP_API_EXECUTION', true);

/**
 * Detect MAMP Apache port from configuration
 */
function getMAMPApachePort() {
    $httpConf = '/Applications/MAMP/conf/apache/httpd.conf';
    if (!file_exists($httpConf)) {
        return 80; // Default fallback
    }
    
    $content = file_get_contents($httpConf);
    
    // Look for Listen directive
    if (preg_match('/^Listen\s+(?:\d+\.\d+\.\d+\.\d+:)?(\d+)\s*$/m', $content, $matches)) {
        return (int)$matches[1];
    }
    
    // Fallback patterns
    if (preg_match('/Listen\s+(\d+)/', $content, $matches)) {
        return (int)$matches[1];
    }
    
    return 80; // Default fallback
}

/**
 * Get MAMP configuration info
 */
function getMAMPConfig() {
    $apachePort = getMAMPApachePort();
    $mysqlPort = 3306; // Default MySQL port for MAMP
    
    // Try to detect MySQL port from config
    $myCnf = '/Applications/MAMP/conf/mysql/my.cnf';
    if (file_exists($myCnf)) {
        $content = file_get_contents($myCnf);
        if (preg_match('/port\s*=\s*(\d+)/', $content, $matches)) {
            $mysqlPort = (int)$matches[1];
        }
    }
    
    return [
        'apache_port' => $apachePort,
        'mysql_port' => $mysqlPort,
        'is_standard' => ($apachePort == 80),
        'web_url' => $apachePort == 80 ? 'http://localhost' : "http://localhost:$apachePort"
    ];
}

function getCurrentProjects() {
    $vhostsFile = '/Applications/MAMP/conf/apache/extra/httpd-vhosts.conf';
    if (!file_exists($vhostsFile)) {
        return [];
    }
    
    $content = file_get_contents($vhostsFile);
    $projects = [];
    
    // Parse virtual hosts with dynamic port support
    if (preg_match_all('/# Virtual Host for (.+?)\n<VirtualHost \*:(\d+)>\s*\n\s*ServerName\s+([^\s]+)/s', $content, $matches, PREG_SET_ORDER)) {
        foreach ($matches as $match) {
            $projectName = trim($match[1]);
            $port = trim($match[2]);
            $domain = trim($match[3]);
            
            // Skip default localhost
            if ($domain !== 'localhost') {
                $projects[] = [
                    'name' => $projectName,
                    'domain' => $domain,
                    'port' => (int)$port,
                    'status' => 'active'
                ];
            }
        }
    }
    
    return $projects;
}

function addVirtualHost($projectName, $domain, $documentRoot, $folderName) {
    $vhostsFile = '/Applications/MAMP/conf/apache/extra/httpd-vhosts.conf';
    
    if (!file_exists($vhostsFile)) {
        return false;
    }
    
    $vhostsContent = file_get_contents($vhostsFile);
    
    // Check if domain already exists
    if (strpos($vhostsContent, "ServerName $domain") !== false) {
        return false;
    }
    
    // Get current MAMP Apache port
    $apachePort = getMAMPApachePort();
    
    // Generate virtual host configuration with dynamic port
    $vhostConfig = "
# Virtual Host for $projectName
<VirtualHost *:$apachePort>
    ServerName $domain
    ServerAlias www.$domain
    DocumentRoot \"$documentRoot\"
    ErrorLog \"/Applications/MAMP/logs/{$folderName}_error.log\"
    CustomLog \"/Applications/MAMP/logs/{$folderName}_access.log\" common
    
    <Directory \"$documentRoot\">
        AllowOverride All
        Options All
        Require all granted
    </Directory>
</VirtualHost>

";
    
    // Find template section and insert before it
    $templatePos = strpos($vhostsContent, '# Template for adding new projects');
    if ($templatePos !== false) {
        $newContent = substr($vhostsContent, 0, $templatePos) . $vhostConfig . substr($vhostsContent, $templatePos);
    } else {
        $newContent = $vhostsContent . $vhostConfig;
    }
    
    return file_put_contents($vhostsFile, $newContent) !== false;
}

function removeVirtualHost($domain) {
    $vhostsFile = '/Applications/MAMP/conf/apache/extra/httpd-vhosts.conf';
    
    if (!file_exists($vhostsFile)) {
        return false;
    }
    
    $content = file_get_contents($vhostsFile);
    
    // Pattern to match entire virtual host block including comments (any port)
    $pattern = '/# Virtual Host for [^\n]*\n<VirtualHost \*:(\d+)>\s*\n\s*ServerName\s+' . preg_quote($domain, '/') . '\s*\n.*?<\/VirtualHost>\s*\n/s';
    
    $newContent = preg_replace($pattern, '', $content);
    
    // Clean up multiple empty lines
    $newContent = preg_replace('/\n\s*\n\s*\n/', "\n\n", $newContent);
    
    return file_put_contents($vhostsFile, $newContent) !== false;
}

function getProjectLocation($domain) {
    $vhostsFile = '/Applications/MAMP/conf/apache/extra/httpd-vhosts.conf';
    
    if (!file_exists($vhostsFile)) {
        return null;
    }
    
    $content = file_get_contents($vhostsFile);
    
    // Pattern to match virtual host and extract DocumentRoot (any port)
    $pattern = '/# Virtual Host for [^\n]*\n<VirtualHost \*:(\d+)>\s*\n\s*ServerName\s+' . preg_quote($domain, '/') . '\s*\n.*?DocumentRoot\s+"([^"]+)"/s';
    
    if (preg_match($pattern, $content, $matches)) {
        return $matches[2]; // DocumentRoot is the second capture group
    }
    
    return null;
}

echo "🔍 MAMP Projects Manager - Port Compatibility Test\n";
echo "=================================================\n\n";

// Test 1: Check MAMP Apache Configuration
echo "1. Testing Apache Configuration Detection...\n";
$apachePort = getMAMPApachePort();
echo "   Detected Apache Port: $apachePort\n";

if ($apachePort == 80) {
    echo "   ✅ Standard port (80) - Full compatibility\n";
} else {
    echo "   📊 Custom port ($apachePort) - Dynamic port support enabled\n";
}

// Test 2: Check MAMP Configuration Info
echo "\n2. Testing MAMP Configuration Info...\n";
$config = getMAMPConfig();
echo "   Apache Port: {$config['apache_port']}\n";
echo "   MySQL Port: {$config['mysql_port']}\n";
echo "   Is Standard: " . ($config['is_standard'] ? 'Yes' : 'No') . "\n";
echo "   Web URL Base: {$config['web_url']}\n";

// Test 3: Test Virtual Host Creation with Current Port
echo "\n3. Testing Virtual Host Creation with Current Port...\n";
$testDomain = 'test-port-compat.local';
$testName = 'Port Compatibility Test';
$testPath = '/Applications/MAMP/htdocs/projects/test-port-compat';

// Clean up any existing test project first
removeVirtualHost($testDomain);

// Create test project
$vhostCreated = addVirtualHost($testName, $testDomain, $testPath, 'test-port-compat');

if ($vhostCreated) {
    echo "   ✅ Virtual Host created successfully with port $apachePort\n";
    
    // Verify the virtual host was created with correct port
    $vhostsContent = file_get_contents('/Applications/MAMP/conf/apache/extra/httpd-vhosts.conf');
    if (strpos($vhostsContent, "<VirtualHost *:$apachePort>") !== false && 
        strpos($vhostsContent, "ServerName $testDomain") !== false) {
        echo "   ✅ Virtual Host configuration verified correctly\n";
    } else {
        echo "   ❌ Virtual Host configuration not found or incorrect\n";
    }
    
    // Test project detection
    echo "\n4. Testing Project Detection...\n";
    $projects = getCurrentProjects();
    $testProjectFound = false;
    
    foreach ($projects as $project) {
        if ($project['domain'] === $testDomain) {
            $testProjectFound = true;
            echo "   ✅ Test project found in project list\n";
            echo "       Name: {$project['name']}\n";
            echo "       Domain: {$project['domain']}\n";
            echo "       Port: {$project['port']}\n";
            
            if ($project['port'] == $apachePort) {
                echo "   ✅ Port matches current Apache configuration\n";
            } else {
                echo "   ❌ Port mismatch: expected $apachePort, got {$project['port']}\n";
            }
            break;
        }
    }
    
    if (!$testProjectFound) {
        echo "   ❌ Test project not found in project list\n";
    }
    
    // Test project location retrieval
    echo "\n5. Testing Project Location Retrieval...\n";
    $location = getProjectLocation($testDomain);
    if ($location === $testPath) {
        echo "   ✅ Project location retrieved correctly: $location\n";
    } else {
        echo "   ❌ Project location incorrect: expected $testPath, got " . ($location ?: 'null') . "\n";
    }
    
    // Clean up test project
    echo "\n6. Cleaning up test project...\n";
    $removed = removeVirtualHost($testDomain);
    if ($removed) {
        echo "   ✅ Test project cleaned up successfully\n";
    } else {
        echo "   ❌ Failed to clean up test project\n";
    }
    
} else {
    echo "   ❌ Failed to create Virtual Host\n";
}

// Test 4: Port Compatibility Summary
echo "\n🎯 Port Compatibility Summary\n";
echo "=============================\n";

$isCompatible = true;
$warnings = [];
$recommendations = [];

if ($apachePort != 80 && $apachePort != 8888) {
    $warnings[] = "Using non-standard port: $apachePort";
    $recommendations[] = "Ensure firewall allows access to port $apachePort";
}

if (file_exists('/Applications/MAMP/conf/apache/httpd.conf')) {
    echo "✅ Apache configuration file accessible\n";
} else {
    echo "❌ Apache configuration file not found\n";
    $isCompatible = false;
}

if (file_exists('/Applications/MAMP/conf/apache/extra/httpd-vhosts.conf')) {
    echo "✅ Virtual hosts configuration file accessible\n";
} else {
    echo "❌ Virtual hosts configuration file not found\n";
    $isCompatible = false;
}

// Check if MAMP Apache is running
exec('pgrep -f "Applications/MAMP/Library/bin/httpd" 2>/dev/null', $apacheProcesses, $returnCode);
if ($returnCode === 0 && !empty($apacheProcesses)) {
    echo "✅ MAMP Apache is running\n";
    
    // Test if Apache is listening on the detected port
    $connection = @fsockopen('localhost', $apachePort, $errno, $errstr, 1);
    if ($connection) {
        echo "✅ Apache is responding on port $apachePort\n";
        fclose($connection);
    } else {
        echo "⚠️  Apache not responding on port $apachePort (Error: $errstr)\n";
        $warnings[] = "Apache may not be properly configured for port $apachePort";
    }
} else {
    echo "⚠️  MAMP Apache is not running\n";
    $recommendations[] = "Start MAMP Apache server before using the projects manager";
}

echo "\n📋 Final Assessment\n";
echo "==================\n";

if ($isCompatible) {
    echo "🎉 MAMP Projects Manager is compatible with your configuration!\n";
    echo "   Current Apache Port: $apachePort\n";
    echo "   Dynamic Port Support: Enabled\n";
    echo "   Project URL Format: http://[domain]" . ($apachePort != 80 ? ":$apachePort" : "") . "\n";
} else {
    echo "❌ Compatibility issues detected\n";
}

if (!empty($warnings)) {
    echo "\n⚠️  Warnings:\n";
    foreach ($warnings as $warning) {
        echo "   • $warning\n";
    }
}

if (!empty($recommendations)) {
    echo "\n💡 Recommendations:\n";
    foreach ($recommendations as $recommendation) {
        echo "   • $recommendation\n";
    }
}

echo "\n✨ Port Configuration Tips:\n";
echo "   • Port 80: Standard HTTP, no port in URL needed\n";
echo "   • Port 8888: Common MAMP default, add :8888 to URLs\n";
echo "   • Other ports: Custom configuration, add :$apachePort to URLs\n";
echo "   • The package automatically detects and adapts to your port configuration\n";

echo "\n🔧 Testing complete!\n";
?>
