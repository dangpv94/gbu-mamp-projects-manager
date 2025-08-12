<?php
/**
 * MAMP Projects API
 * Handles automated virtual host creation and project management
 */

// Start session for logging
session_start();

// Basic hosts management functions are now implemented directly in this file

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

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

function respond($success, $message, $data = null) {
    echo json_encode([
        'success' => $success,
        'message' => $message,
        'data' => $data,
        'timestamp' => date('c')
    ]);
    exit;
}

function sanitizeProjectName($name) {
    return strtolower(preg_replace('/[^a-z0-9-]/i', '-', $name));
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

function addHostsEntry($domain) {
    $hostsFile = '/etc/hosts';
    $hostsContent = file_get_contents($hostsFile);
    
    // Check if entry already exists
    if (strpos($hostsContent, $domain) !== false) {
        return true; // Already exists
    }
    
    // Use echo and tee method which works better from PHP
    $hostsEntry = "127.0.0.1\t$domain";
    $command = "echo " . escapeshellarg($hostsEntry) . " | sudo tee -a " . escapeshellarg($hostsFile) . " >/dev/null 2>&1";
    exec($command, $output, $returnVar);
    
    return $returnVar === 0;
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

/**
 * Diagnose project path issues
 */
function diagnoseProjectPaths() {
    $vhostsFile = '/Applications/MAMP/conf/apache/extra/httpd-vhosts.conf';
    if (!file_exists($vhostsFile)) {
        return ['error' => 'Virtual hosts file not found'];
    }
    
    $content = file_get_contents($vhostsFile);
    $issues = [];
    $projects = [];
    
    // Extract projects and their paths
    if (preg_match_all('/# Virtual Host for (.+?)\n.*?DocumentRoot\s+\"([^\"]+)\".*?ServerName\s+([^\s\n]+)/s', $content, $matches, PREG_SET_ORDER)) {
        foreach ($matches as $match) {
            $projectName = trim($match[1]);
            $documentRoot = trim($match[2]);
            $domain = trim($match[3]);
            
            // Skip localhost default
            if ($domain === 'localhost') continue;
            
            $project = [
                'name' => $projectName,
                'domain' => $domain,
                'document_root' => $documentRoot,
                'exists' => file_exists($documentRoot),
                'issues' => []
            ];
            
            // Check if path exists
            if (!file_exists($documentRoot)) {
                $project['issues'][] = 'document_root_missing';
                $issues[] = [
                    'type' => 'missing_document_root',
                    'project' => $projectName,
                    'domain' => $domain,
                    'path' => $documentRoot,
                    'severity' => 'high'
                ];
            }
            
            // Check if it's pointing to default htdocs (common issue)
            if (strpos($documentRoot, '/Applications/MAMP/htdocs') === 0 && $documentRoot !== '/Applications/MAMP/htdocs') {
                $project['issues'][] = 'pointing_to_htdocs';
                $issues[] = [
                    'type' => 'pointing_to_htdocs',
                    'project' => $projectName,
                    'domain' => $domain,
                    'path' => $documentRoot,
                    'severity' => 'medium'
                ];
            }
            
            // Check if path contains old user directory (migration issue)
            if (preg_match('/\/Users\/([^\/]+)\//', $documentRoot, $userMatch)) {
                $pathUser = $userMatch[1];
                $currentUser = get_current_user();
                if ($pathUser !== $currentUser) {
                    $project['issues'][] = 'wrong_user_path';
                    $issues[] = [
                        'type' => 'wrong_user_path',
                        'project' => $projectName,
                        'domain' => $domain,
                        'path' => $documentRoot,
                        'old_user' => $pathUser,
                        'current_user' => $currentUser,
                        'severity' => 'high'
                    ];
                }
            }
            
            $projects[] = $project;
        }
    }
    
    // Check hosts file entries
    $hostsFile = '/etc/hosts';
    $hostsContent = file_exists($hostsFile) ? file_get_contents($hostsFile) : '';
    $hostsIssues = [];
    
    foreach ($projects as $project) {
        if (strpos($hostsContent, $project['domain']) === false) {
            $hostsIssues[] = [
                'type' => 'missing_hosts_entry',
                'project' => $project['name'],
                'domain' => $project['domain'],
                'severity' => 'medium'
            ];
        }
    }
    
    return [
        'projects' => $projects,
        'issues' => array_merge($issues, $hostsIssues),
        'total_issues' => count($issues) + count($hostsIssues),
        'summary' => [
            'total_projects' => count($projects),
            'broken_paths' => count(array_filter($projects, fn($p) => !$p['exists'])),
            'migration_issues' => count(array_filter($issues, fn($i) => $i['type'] === 'wrong_user_path')),
            'hosts_issues' => count($hostsIssues)
        ]
    ];
}

/**
 * Auto-fix project path issues
 */
function autoFixProjectPaths($fixMode = 'smart') {
    $diagnosis = diagnoseProjectPaths();
    
    if ($diagnosis['total_issues'] === 0) {
        return ['success' => true, 'message' => 'No issues found to fix', 'fixes_applied' => []];
    }
    
    $vhostsFile = '/Applications/MAMP/conf/apache/extra/httpd-vhosts.conf';
    $backupFile = '/Applications/MAMP/htdocs/projects/backups/vhosts_backup_autofix_' . date('Y-m-d_H-i-s') . '.conf';
    
    // Create backup
    if (!is_dir(dirname($backupFile))) {
        mkdir(dirname($backupFile), 0755, true);
    }
    copy($vhostsFile, $backupFile);
    
    $content = file_get_contents($vhostsFile);
    $fixesApplied = [];
    $currentUser = get_current_user();
    $userHome = $_SERVER['HOME'] ?? '/Users/' . $currentUser;
    
    foreach ($diagnosis['issues'] as $issue) {
        if ($issue['type'] === 'wrong_user_path' || $issue['type'] === 'missing_document_root') {
            $oldPath = $issue['path'];
            $newPath = null;
            
            switch ($fixMode) {
                case 'smart':
                    // Try to find the project in common locations
                    $projectBasename = basename($oldPath);
                    $possiblePaths = [
                        "$userHome/Works/$projectBasename",
                        "$userHome/Documents/$projectBasename",
                        "$userHome/Desktop/$projectBasename",
                        "$userHome/Developer/$projectBasename",
                        "/Applications/MAMP/htdocs/projects/$projectBasename"
                    ];
                    
                    foreach ($possiblePaths as $path) {
                        if (file_exists($path)) {
                            $newPath = $path;
                            break;
                        }
                    }
                    
                    // If not found, create in Works directory
                    if (!$newPath) {
                        $newPath = "$userHome/Works/$projectBasename";
                        if (!is_dir("$userHome/Works")) {
                            mkdir("$userHome/Works", 0755, true);
                        }
                        mkdir($newPath, 0755, true);
                        file_put_contents("$newPath/index.html", 
                            "<h1>Project: {$issue['project']}</h1><p>Please copy your project files here.</p>");
                    }
                    break;
                    
                case 'mamp':
                    // Move to MAMP projects directory
                    $projectBasename = basename($oldPath);
                    $newPath = "/Applications/MAMP/htdocs/projects/$projectBasename";
                    if (!is_dir('/Applications/MAMP/htdocs/projects')) {
                        mkdir('/Applications/MAMP/htdocs/projects', 0755, true);
                    }
                    if (!file_exists($newPath)) {
                        mkdir($newPath, 0755, true);
                        file_put_contents("$newPath/index.html", 
                            "<h1>Project: {$issue['project']}</h1><p>Please copy your project files here.</p>");
                    }
                    break;
                    
                case 'works':
                    // Move to Works directory
                    $projectBasename = basename($oldPath);
                    $newPath = "$userHome/Works/$projectBasename";
                    if (!is_dir("$userHome/Works")) {
                        mkdir("$userHome/Works", 0755, true);
                    }
                    if (!file_exists($newPath)) {
                        mkdir($newPath, 0755, true);
                        file_put_contents("$newPath/index.html", 
                            "<h1>Project: {$issue['project']}</h1><p>Please copy your project files here.</p>");
                    }
                    break;
            }
            
            if ($newPath) {
                // Update DocumentRoot
                $content = preg_replace(
                    '/DocumentRoot\s+\"' . preg_quote($oldPath, '/') . '\"/i',
                    'DocumentRoot "' . $newPath . '"',
                    $content
                );
                
                // Update Directory path
                $content = preg_replace(
                    '/<Directory\s+\"' . preg_quote($oldPath, '/') . '\">/i',
                    '<Directory "' . $newPath . '">',
                    $content
                );
                
                $fixesApplied[] = [
                    'project' => $issue['project'],
                    'domain' => $issue['domain'],
                    'old_path' => $oldPath,
                    'new_path' => $newPath,
                    'action' => 'path_updated'
                ];
            }
        }
    }
    
    // Save updated vhosts file
    file_put_contents($vhostsFile, $content);
    
    // Try to fix hosts entries (note: this requires manual intervention for sudo)
    $hostsMessage = '';
    $hostsCommands = [];
    foreach ($diagnosis['issues'] as $issue) {
        if ($issue['type'] === 'missing_hosts_entry') {
            $hostsCommands[] = "echo '127.0.0.1\t{$issue['domain']}' | sudo tee -a /etc/hosts";
        }
    }
    
    if (!empty($hostsCommands)) {
        $hostsMessage = 'Hosts file entries need manual addition. Run these commands: ' . implode('; ', $hostsCommands);
    }
    
    return [
        'success' => true,
        'message' => 'Auto-fix completed successfully',
        'fixes_applied' => $fixesApplied,
        'backup_file' => $backupFile,
        'hosts_message' => $hostsMessage,
        'restart_required' => true
    ];
}

function removeHostsEntry($domain) {
    $hostsFile = '/etc/hosts';
    $hostsContent = file_get_contents($hostsFile);
    
    // Remove domain and www.domain entries
    $lines = explode("\n", $hostsContent);
    $newLines = [];
    
    foreach ($lines as $line) {
        $line = trim($line);
        // Skip lines containing our domain
        if ($line && (strpos($line, $domain) !== false || strpos($line, "www.$domain") !== false)) {
            continue;
        }
        $newLines[] = $line;
    }
    
    $newContent = implode("\n", $newLines);
    
    // Create temporary file
    $tempFile = tempnam(sys_get_temp_dir(), 'hosts_');
    file_put_contents($tempFile, $newContent);
    
    // Use sudo to copy
    $command = "sudo cp " . escapeshellarg($tempFile) . " " . escapeshellarg($hostsFile) . " 2>/dev/null";
    exec($command, $output, $returnVar);
    
    unlink($tempFile);
    
    return $returnVar === 0;
}

function removeProjectDirectory($projectName) {
    $projectDir = "/Applications/MAMP/htdocs/projects/" . sanitizeProjectName($projectName);
    
    if (file_exists($projectDir)) {
        $command = "rm -rf " . escapeshellarg($projectDir);
        exec($command, $output, $returnVar);
        return $returnVar === 0;
    }
    
    return true; // Already doesn't exist
}

function removeSingleProject($domain) {
    // Find project info first
    $projects = getCurrentProjects();
    $projectToRemove = null;
    
    foreach ($projects as $project) {
        if ($project['domain'] === $domain) {
            $projectToRemove = $project;
            break;
        }
    }
    
    if (!$projectToRemove) {
        return [
            'success' => false,
            'message' => 'Project not found',
            'project' => null
        ];
    }
    
    $projectName = $projectToRemove['name'];
    $errors = [];
    
    try {
        // Remove virtual host
        $vhostRemoved = removeVirtualHost($domain);
        if (!$vhostRemoved) {
            $errors[] = 'Failed to remove virtual host configuration';
        }
        
        // Remove hosts entry
        $hostsRemoved = removeHostsEntry($domain);
        if (!$hostsRemoved) {
            $errors[] = 'Could not remove hosts entry automatically (may need manual cleanup)';
        }
        
        // Remove project directory (only if it's in our projects folder)
        $folderRemoved = removeProjectDirectory($projectName);
        if (!$folderRemoved) {
            $errors[] = 'Failed to remove project folder';
        }
        
        return [
            'success' => true,
            'project' => [
                'name' => $projectName,
                'domain' => $domain,
                'vhost_removed' => $vhostRemoved,
                'hosts_removed' => $hostsRemoved,
                'folder_removed' => $folderRemoved
            ],
            'errors' => $errors,
            'hostsWarning' => !$hostsRemoved ? 'Hosts entry may need to be removed manually from /etc/hosts' : null
        ];
        
    } catch (Exception $e) {
        return [
            'success' => false,
            'message' => 'Error removing project: ' . $e->getMessage(),
            'project' => $projectToRemove
        ];
    }
}

function removeAllProjects() {
    $projects = getCurrentProjects();
    $removedProjects = [];
    $errors = [];
    
    foreach ($projects as $project) {
        $domain = $project['domain'];
        $projectName = $project['name'];
        
        try {
            // Remove virtual host
            $vhostRemoved = removeVirtualHost($domain);
            
            // Remove hosts entry
            $hostsRemoved = removeHostsEntry($domain);
            
            // Remove project directory (only if it's in our projects folder)
            $folderRemoved = removeProjectDirectory($projectName);
            
            $removedProjects[] = [
                'name' => $projectName,
                'domain' => $domain,
                'vhost_removed' => $vhostRemoved,
                'hosts_removed' => $hostsRemoved,
                'folder_removed' => $folderRemoved
            ];
            
        } catch (Exception $e) {
            $errors[] = "Error removing {$projectName}: " . $e->getMessage();
        }
    }
    
    return [
        'removed_projects' => $removedProjects,
        'errors' => $errors,
        'total_removed' => count($removedProjects)
    ];
}

function runSetupScript($domain) {
    $messages = [];
    $hostsSuccess = false;
    $apacheSuccess = false;
    
    try {
        // Try to add hosts entry using basic function
        $hostsSuccess = addHostsEntry($domain);
        
        if ($hostsSuccess) {
            $messages[] = "✅ Hosts entry added successfully";
        } else {
            $messages[] = "⚠️ Could not add hosts entry automatically";
        }
        
    } catch (Exception $e) {
        $messages[] = "⚠️ Could not add hosts entry: " . $e->getMessage();
    }
    
    // Try to restart Apache via MAMP
    $apacheSuccess = restartMAMPApache();
    
    if ($apacheSuccess) {
        $messages[] = "✅ MAMP Apache restarted successfully";
    } else {
        $messages[] = "⚠️ Could not restart Apache automatically";
    }
    
    $outputString = implode("\n", $messages);
    $success = $hostsSuccess && $apacheSuccess;
    
    if ($success) {
        $outputString .= "\n\n🎉 Setup complete! Your project is ready:\n   URL: http://$domain";
        $outputString .= "\n✅ Virtual host configured";
        
    } else {
        $outputString .= "\n\n⚠️ Automatic setup incomplete. You may need to:";
        $outputString .= "\n   1. Check MAMP is running";
        $outputString .= "\n   2. Add hosts entry manually: echo '127.0.0.1 $domain' | sudo tee -a /etc/hosts";
        $outputString .= "\n   3. Restart MAMP to apply changes";
    }
    
    return [
        'success' => $success,
        'output' => $outputString,
        'error' => $success ? null : 'Some setup steps failed',
        'requires_setup' => !$success,
        'project_url' => "http://$domain"
    ];
}

function restartMAMPApache() {
    $messages = [];
    $success = false;
    
    try {
        // Method 1: Try MAMP built-in scripts (most reliable)
        $messages[] = "Attempting to stop Apache using MAMP scripts...";
        exec('/Applications/MAMP/bin/stopApache.sh 2>&1', $stopOutput, $stopReturn);
        
        // Kill any remaining httpd processes
        exec('pkill -f "Applications/MAMP/Library/bin/httpd" 2>/dev/null');
        
        // Wait a moment
        sleep(1);
        
        // Start Apache
        $messages[] = "Starting Apache...";
        exec('/Applications/MAMP/bin/startApache.sh 2>&1', $startOutput, $startReturn);
        
        // Check if Apache is running
        exec('pgrep -f "Applications/MAMP/Library/bin/httpd" 2>/dev/null', $checkOutput, $checkReturn);
        
        if ($checkReturn === 0 && !empty($checkOutput)) {
            $messages[] = "Apache restarted successfully using MAMP scripts";
            $success = true;
        } else {
            // Method 2: Try apachectl directly
            $messages[] = "Trying apachectl restart...";
            exec('/Applications/MAMP/Library/bin/apachectl restart 2>&1', $apacheOutput, $apacheReturn);
            
            // Check again
            exec('pgrep -f "Applications/MAMP/Library/bin/httpd" 2>/dev/null', $checkOutput2, $checkReturn2);
            
            if ($checkReturn2 === 0 && !empty($checkOutput2)) {
                $messages[] = "Apache restarted successfully using apachectl";
                $success = true;
            } else {
                // Method 3: Force restart with manual process management
                $messages[] = "Attempting force restart...";
                
                // Kill all httpd processes forcefully
                exec('pkill -9 -f "httpd" 2>/dev/null');
                sleep(2);
                
                // Try to start using httpd directly
                exec('/Applications/MAMP/Library/bin/httpd -D FOREGROUND 2>&1 &', $directOutput, $directReturn);
                sleep(1);
                
                // Final check
                exec('pgrep -f "Applications/MAMP/Library/bin/httpd" 2>/dev/null', $finalCheck, $finalReturn);
                
                if ($finalReturn === 0 && !empty($finalCheck)) {
                    $messages[] = "Apache started successfully using direct method";
                    $success = true;
                } else {
                    $messages[] = "Failed to restart Apache. All methods exhausted.";
                    $messages[] = "Stop output: " . implode(' ', $stopOutput);
                    $messages[] = "Start output: " . implode(' ', $startOutput);
                    if (isset($apacheOutput)) {
                        $messages[] = "Apache output: " . implode(' ', $apacheOutput);
                    }
                }
            }
        }
        
    } catch (Exception $e) {
        $messages[] = "Exception during restart: " . $e->getMessage();
        $success = false;
    }
    
    // Store messages for debugging
    $_SESSION['last_apache_restart_log'] = $messages;
    
    return $success;
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

function updateProjectLocation($domain, $newLocation) {
    $vhostsFile = '/Applications/MAMP/conf/apache/extra/httpd-vhosts.conf';
    
    if (!file_exists($vhostsFile)) {
        return false;
    }
    
    $content = file_get_contents($vhostsFile);
    
    // Get the current DocumentRoot
    $currentLocation = getProjectLocation($domain);
    if (!$currentLocation) {
        return false; // Project not found
    }
    
    // Pattern to match the entire virtual host block for this domain (any port)
    $pattern = '/(# Virtual Host for [^\n]*\n<VirtualHost \*:(\d+)>\s*\n\s*ServerName\s+' . preg_quote($domain, '/') . '\s*\n.*?DocumentRoot\s+")([^"]+)(".*?<\/VirtualHost>)/s';
    
    // Replace the DocumentRoot path and Directory path
    $newContent = preg_replace_callback($pattern, function($matches) use ($newLocation, $currentLocation) {
        $vhostBlock = $matches[0];
        
        // Replace DocumentRoot
        $vhostBlock = str_replace('DocumentRoot "' . $currentLocation . '"', 'DocumentRoot "' . $newLocation . '"', $vhostBlock);
        
        // Replace Directory path
        $vhostBlock = str_replace('<Directory "' . $currentLocation . '">', '<Directory "' . $newLocation . '">', $vhostBlock);
        
        return $vhostBlock;
    }, $content);
    
    if ($newContent === $content) {
        return false; // No changes made
    }
    
    return file_put_contents($vhostsFile, $newContent) !== false;
}

function createProjectDirectory($sourcePath, $projectDir, $locationType, $projectName, $domain) {
    if ($locationType === 'link') {
        // For link mode, just verify source exists
        return file_exists($sourcePath);
    }
    
    // For copy mode
    if ($sourcePath && file_exists($sourcePath)) {
        // Copy existing project
        $command = "cp -R " . escapeshellarg($sourcePath) . " " . escapeshellarg($projectDir) . " 2>/dev/null";
        exec($command, $output, $returnVar);
        return $returnVar === 0;
    } else {
        // Create new project directory
        if (!file_exists($projectDir)) {
            mkdir($projectDir, 0755, true);
        }
        
        // Create basic index.html
        $indexContent = "<!DOCTYPE html>
<html lang=\"en\">
<head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>$projectName</title>
    <style>
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            text-align: center;
            max-width: 500px;
        }
        h1 { 
            color: #333;
            margin-bottom: 10px;
            font-size: 2.5em;
        }
        .status {
            background: #28a745;
            color: white;
            padding: 8px 16px;
            border-radius: 20px;
            display: inline-block;
            margin: 20px 0;
            font-weight: bold;
        }
        .domain {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
            font-family: monospace;
            color: #007bff;
            font-size: 18px;
            font-weight: bold;
        }
        .info {
            color: #666;
            margin-top: 20px;
            line-height: 1.6;
        }
        .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            color: #888;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class=\"container\">
        <h1>🚀 $projectName</h1>
        <div class=\"status\">✅ Project Ready</div>
        <div class=\"domain\">$domain</div>
        <div class=\"info\">
            Your MAMP virtual host is successfully configured and ready for development!
            <br><br>
            You can now start building your project in this directory.
        </div>
        <div class=\"footer\">
            Created with MAMP Projects Manager<br>
            " . date('Y-m-d H:i:s') . "
        </div>
    </div>
</body>
</html>";
        
        return file_put_contents($projectDir . '/index.html', $indexContent) !== false;
    }
}

// Main API logic
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

if ($method === 'GET') {
    // Return current projects
    $action = $_GET['action'] ?? '';
    
    if ($action === 'projects') {
        $projects = getCurrentProjects();
        respond(true, 'Projects retrieved successfully', $projects);
    } elseif ($action === 'mamp_config') {
        $config = getMAMPConfig();
        respond(true, 'MAMP configuration retrieved successfully', $config);
    } elseif ($action === 'get_user_info') {
        // Get current user information
        $username = exec('whoami');
        $homeDir = exec('echo $HOME');
        
        // Alternative method if $HOME is not available
        if (empty($homeDir) || $homeDir === '$HOME') {
            $homeDir = '/Users/' . $username;
        }
        
        respond(true, 'User information retrieved successfully', [
            'username' => $username,
            'home' => $homeDir,
            'detected_paths' => [
                'works' => $homeDir . '/Works',
                'desktop' => $homeDir . '/Desktop', 
                'documents' => $homeDir . '/Documents',
                'downloads' => $homeDir . '/Downloads'
            ]
        ]);
    } else {
        respond(false, 'Invalid action');
    }
    
} elseif ($method === 'POST') {
    // Handle project creation
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        respond(false, 'Invalid JSON input');
    }
    
    $action = $input['action'] ?? '';
    
    if ($action === 'create_project') {
        // Validate required fields
        if (empty($input['projectName']) || empty($input['domain'])) {
            respond(false, 'Project name and domain are required');
        }
        
        $projectName = trim($input['projectName']);
        $domain = trim($input['domain']);
        $sourcePath = trim($input['sourcePath'] ?? '');
        $locationType = $input['locationType'] ?? 'copy';
        
        $folderName = sanitizeProjectName($projectName);
        
        // Validate link mode requirements
        if ($locationType === 'link' && empty($sourcePath)) {
            respond(false, 'Source path is required for link mode');
        }
        
        if ($locationType === 'link' && !file_exists($sourcePath)) {
            respond(false, 'Source path does not exist: ' . $sourcePath);
        }
        
        // Determine document root
        if ($locationType === 'link') {
            $documentRoot = $sourcePath;
            $projectDir = $sourcePath;
        } else {
            $documentRoot = "/Applications/MAMP/htdocs/projects/$folderName";
            $projectDir = "/Applications/MAMP/htdocs/projects/$folderName";
        }
        
        try {
            // Step 1: Create/setup project directory (only for copy mode)
            if ($locationType === 'copy') {
                if (!createProjectDirectory($sourcePath, $projectDir, $locationType, $projectName, $domain)) {
                    respond(false, 'Failed to create/setup project directory');
                }
            } else {
                // For link mode, just verify source exists
                if (!file_exists($sourcePath)) {
                    respond(false, 'Source path does not exist: ' . $sourcePath);
                }
            }
            
            // Step 2: Add virtual host configuration
            if (!addVirtualHost($projectName, $domain, $documentRoot, $folderName)) {
                respond(false, 'Failed to add virtual host configuration (domain may already exist)');
            }
            
            // Step 3: Try automatic setup using the setup script
            $setupResult = runSetupScript($domain);
            
            // Prepare response data
            $responseData = [
                'project' => [
                    'name' => $projectName,
                    'domain' => $domain,
                    'documentRoot' => $documentRoot,
                    'mode' => $locationType,
                    'url' => "http://$domain"
                ],
                'setupCompleted' => $setupResult['success'],
                'setupOutput' => $setupResult['output'],
                'setupWarning' => !$setupResult['success'] ? 'Automatic setup failed. Please run setup script manually.' : null,
                'hostsEntryAdded' => $setupResult['success'], // If setup succeeded, hosts was added
                'hostsWarning' => !$setupResult['success'] ? 'Could not automatically complete setup. You may need to run the setup script manually.' : null
            ];
            
            $message = $setupResult['success'] ? 
                'Project created and setup completed automatically! Your project is ready to use.' : 
                'Project created successfully! Please run the setup script to complete configuration.';
            
            respond(true, $message, $responseData);
            
        } catch (Exception $e) {
            respond(false, 'Error creating project: ' . $e->getMessage());
        }
        
    } elseif ($action === 'remove_project') {
        // Validate required fields
        if (empty($input['domain'])) {
            respond(false, 'Domain is required');
        }
        
        $domain = trim($input['domain']);
        
        try {
            $result = removeSingleProject($domain);
            
            if ($result['success']) {
                $message = "Project '{$result['project']['name']}' has been removed successfully.";
                if (!empty($result['errors'])) {
                    $message .= " Some operations may require manual cleanup.";
                }
                respond(true, $message, $result);
            } else {
                respond(false, $result['message'], $result);
            }
            
        } catch (Exception $e) {
            respond(false, 'Error removing project: ' . $e->getMessage());
        }
        
    } elseif ($action === 'remove_all_projects') {
        try {
            $result = removeAllProjects();
            
            $message = "Successfully removed {$result['total_removed']} projects.";
            if (!empty($result['errors'])) {
                $message .= " Some operations may require manual cleanup.";
            }
            
            respond(true, $message, $result);
            
        } catch (Exception $e) {
            respond(false, 'Error removing projects: ' . $e->getMessage());
        }
        
    } elseif ($action === 'restart_apache') {
        // Restart Apache Server
        try {
            $success = restartMAMPApache();
            
            if ($success) {
                respond(true, 'Apache server restarted successfully', [
                    'timestamp' => date('Y-m-d H:i:s'),
                    'status' => 'restarted'
                ]);
            } else {
                respond(false, 'Failed to restart Apache server. Please try manually or check MAMP status.');
            }
            
        } catch (Exception $e) {
            respond(false, 'Error restarting Apache: ' . $e->getMessage());
        }
        
    } elseif ($action === 'get_project_location') {
        // Get current project location from vhosts config
        if (empty($input['domain'])) {
            respond(false, 'Domain is required');
        }
        
        $domain = trim($input['domain']);
        
        try {
            $location = getProjectLocation($domain);
            
            if ($location) {
                respond(true, 'Project location retrieved successfully', [
                    'domain' => $domain,
                    'documentRoot' => $location
                ]);
            } else {
                respond(false, 'Project not found or unable to read virtual host configuration');
            }
            
        } catch (Exception $e) {
            respond(false, 'Error getting project location: ' . $e->getMessage());
        }
        
    } elseif ($action === 'update_project_location') {
        // Update project location
        if (empty($input['domain']) || empty($input['newLocation'])) {
            respond(false, 'Domain and new location are required');
        }
        
        $domain = trim($input['domain']);
        $newLocation = trim($input['newLocation']);
        
        try {
            // Verify new location exists
            if (!file_exists($newLocation)) {
                respond(false, "New location does not exist: {$newLocation}");
            }
            
            // Get current location before updating
            $oldLocation = getProjectLocation($domain);
            
            // Update the virtual host configuration
            $success = updateProjectLocation($domain, $newLocation);
            
            if ($success) {
                // Try to restart Apache after updating
                restartMAMPApache();
                
                respond(true, 'Project location updated successfully', [
                    'domain' => $domain,
                    'oldLocation' => $oldLocation,
                    'newLocation' => $newLocation,
                    'timestamp' => date('Y-m-d H:i:s')
                ]);
            } else {
                respond(false, 'Failed to update virtual host configuration');
            }
            
        } catch (Exception $e) {
            respond(false, 'Error updating project location: ' . $e->getMessage());
        }
        
    } elseif ($action === 'restart_logs') {
        // Get Apache restart debug logs
        session_start();
        $logs = $_SESSION['last_apache_restart_log'] ?? ['No restart logs available'];
        
        respond(true, 'Restart logs retrieved', [
            'logs' => $logs,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } elseif ($action === 'diagnose_paths') {
        // Diagnose project path issues
        try {
            $diagnosis = diagnoseProjectPaths();
            
            if (isset($diagnosis['error'])) {
                respond(false, $diagnosis['error']);
            }
            
            respond(true, 'Project paths diagnosis completed', $diagnosis);
            
        } catch (Exception $e) {
            respond(false, 'Error during diagnosis: ' . $e->getMessage());
        }
        
    } elseif ($action === 'auto_fix_paths') {
        // Auto-fix project path issues
        $fixMode = $input['fix_mode'] ?? 'smart';
        
        try {
            $result = autoFixProjectPaths($fixMode);
            
            if ($result['success']) {
                $message = $result['message'];
                if (!empty($result['fixes_applied'])) {
                    $message .= " Applied " . count($result['fixes_applied']) . " fixes.";
                }
                if (!empty($result['hosts_message'])) {
                    $message .= " Note: " . $result['hosts_message'];
                }
                
                respond(true, $message, $result);
            } else {
                respond(false, $result['message'] ?? 'Auto-fix failed', $result);
            }
            
        } catch (Exception $e) {
            respond(false, 'Error during auto-fix: ' . $e->getMessage());
        }
        
    } else {
        respond(false, 'Invalid action');
    }
    
} else {
    respond(false, 'Method not allowed');
}
?>
