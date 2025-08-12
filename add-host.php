<?php
/**
 * MAMP Virtual Host Helper
 * This script helps add new virtual hosts and hosts entries
 * Run this script from terminal with appropriate parameters
 */

if (php_sapi_name() !== 'cli') {
    die("This script must be run from command line\n");
}

function showUsage() {
    echo "Usage: php add-host.php [options]\n";
    echo "Options:\n";
    echo "  --name=PROJECT_NAME     Project name (required)\n";
    echo "  --domain=DOMAIN         Domain name (optional, defaults to project-name.local)\n";
    echo "  --source=SOURCE_PATH    Source path (required for --link mode)\n";
    echo "  --link                  Use original path instead of copying (default: copy)\n";
    echo "  --help                  Show this help message\n";
    echo "\nExamples:\n";
    echo "  # Copy mode (default)\n";
    echo "  php add-host.php --name=\"My New Project\"\n";
    echo "  php add-host.php --name=\"blog\" --source=\"/Users/username/blog\"\n";
    echo "\n  # Link mode (use original path)\n";
    echo "  php add-host.php --name=\"portfolio\" --source=\"/Users/username/portfolio\" --link\n";
    echo "  php add-host.php --name=\"existing-project\" --source=\"/Users/username/Works/project\" --link\n";
}

// Parse command line arguments
$options = getopt('', ['name:', 'domain:', 'source:', 'link', 'help']);

if (isset($options['help'])) {
    showUsage();
    exit(0);
}

if (!isset($options['name'])) {
    echo "Error: Project name is required\n\n";
    showUsage();
    exit(1);
}

$projectName = $options['name'];
$folderName = strtolower(preg_replace('/[^a-z0-9-]/i', '-', $projectName));
$folderName = preg_replace('/-+/', '-', $folderName);
$folderName = trim($folderName, '-');

$domain = isset($options['domain']) ? $options['domain'] : $folderName . '.local';
$sourcePath = isset($options['source']) ? $options['source'] : null;
$linkMode = isset($options['link']);

$projectsDir = '/Applications/MAMP/htdocs/projects';
$vhostsFile = '/Applications/MAMP/conf/apache/extra/httpd-vhosts.conf';
$hostsFile = '/etc/hosts';

// Determine project directory based on mode
if ($linkMode && $sourcePath) {
    $projectDir = $sourcePath;
} else {
    $projectDir = $projectsDir . '/' . $folderName;
}

echo "=== MAMP Virtual Host Setup ===\n";
echo "Project Name: $projectName\n";
echo "Folder Name: $folderName\n";
echo "Domain: $domain\n";
echo "Mode: " . ($linkMode ? "Link (use original path)" : "Copy") . "\n";
echo "Project Directory: $projectDir\n";
if ($sourcePath) {
    echo "Source Path: $sourcePath\n";
}
echo "\n";

// Validate link mode requirements
if ($linkMode && !$sourcePath) {
    die("Error: Link mode requires --source parameter\n");
}

if ($linkMode && !file_exists($sourcePath)) {
    die("Error: Source path does not exist: $sourcePath\n");
}

// Step 1: Handle project directory
if ($linkMode) {
    echo "Step 1: Using existing project at original path...\n";
    echo "✅ Project will use: $projectDir\n";
} else {
    // Copy or create mode
    if ($sourcePath && file_exists($sourcePath)) {
        echo "Step 1: Copying existing project...\n";
        $command = "cp -R " . escapeshellarg($sourcePath) . " " . escapeshellarg($projectDir);
        echo "Running: $command\n";
        system($command, $returnVar);
        
        if ($returnVar !== 0) {
            die("Failed to copy project directory\n");
        }
    } else {
        echo "Step 1: Creating new project directory...\n";
        $command = "mkdir -p " . escapeshellarg($projectDir);
        echo "Running: $command\n";
        system($command, $returnVar);
        
        if ($returnVar !== 0) {
            die("Failed to create project directory\n");
        }
        
        // Create a basic index.html
        $indexContent = "<!DOCTYPE html>
<html>
<head>
    <title>$projectName</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin-top: 100px; }
        h1 { color: #007bff; }
        p { color: #666; }
    </style>
</head>
<body>
    <h1>Welcome to $projectName</h1>
    <p>Your new MAMP project is ready!</p>
    <p>Domain: <a href=\"http://$domain\">$domain</a></p>
    <p>Project directory: $projectDir</p>
</body>
</html>";
        
        file_put_contents($projectDir . '/index.html', $indexContent);
        echo "Created basic index.html file\n";
    }
    echo "✅ Project directory ready\n";
}
echo "\n";

// Step 2: Generate Virtual Host configuration
echo "Step 2: Generating Virtual Host configuration...\n";

$vhostConfig = "
# Virtual Host for $projectName
<VirtualHost *:80>
    ServerName $domain
    ServerAlias www.$domain
    DocumentRoot \"$projectDir\"
    ErrorLog \"/Applications/MAMP/logs/{$folderName}_error.log\"
    CustomLog \"/Applications/MAMP/logs/{$folderName}_access.log\" common
    
    <Directory \"$projectDir\">
        AllowOverride All
        Options All
        Require all granted
    </Directory>
</VirtualHost>

";

// Read current vhosts file
$vhostsContent = file_get_contents($vhostsFile);

// Check if this virtual host already exists
if (strpos($vhostsContent, "ServerName $domain") !== false) {
    echo "⚠️  Virtual host for $domain already exists\n";
} else {
    // Find the template section and insert before it
    $templatePos = strpos($vhostsContent, '# Template for adding new projects');
    if ($templatePos !== false) {
        $newContent = substr($vhostsContent, 0, $templatePos) . $vhostConfig . substr($vhostsContent, $templatePos);
        file_put_contents($vhostsFile, $newContent);
        echo "✅ Virtual host configuration added\n";
    } else {
        echo "⚠️  Could not find template section, appending to end of file\n";
        file_put_contents($vhostsFile, $vhostsContent . $vhostConfig, FILE_APPEND);
    }
}

echo "\n";

// Step 3: Add hosts entry
echo "Step 3: Adding hosts file entry...\n";

$hostsContent = file_get_contents($hostsFile);
$hostsEntry = "127.0.0.1\t$domain";

if (strpos($hostsContent, $domain) !== false) {
    echo "⚠️  Hosts entry for $domain already exists\n";
} else {
    // Try to add hosts entry (requires sudo)
    echo "Adding: $hostsEntry\n";
    echo "This requires sudo access...\n";
    
    $tempFile = tempnam(sys_get_temp_dir(), 'hosts_');
    file_put_contents($tempFile, $hostsContent . "\n" . $hostsEntry . "\n");
    
    $command = "sudo cp " . escapeshellarg($tempFile) . " " . escapeshellarg($hostsFile);
    echo "Running: $command\n";
    system($command, $returnVar);
    
    unlink($tempFile);
    
    if ($returnVar === 0) {
        echo "✅ Hosts entry added\n";
    } else {
        echo "⚠️  Failed to add hosts entry. Please run manually:\n";
        echo "sudo echo '$hostsEntry' >> /etc/hosts\n";
    }
}

echo "\n";

// Final instructions
echo "=== Setup Complete! ===\n";
echo "1. ✅ Project directory created: $projectDir\n";
echo "2. ✅ Virtual host configuration added\n";
echo "3. ✅ Hosts file entry added\n";
echo "\nNext steps:\n";
echo "- Restart MAMP\n";
echo "- Visit: http://$domain\n";
echo "- Edit files in: $projectDir\n";
echo "\nProject URL: http://$domain\n";
?>
