<?php
/**
 * Folder Browser API Endpoint
 * Returns list of directories for the given path
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Get the requested path
$path = isset($_GET['path']) ? $_GET['path'] : '/Users';

// Sanitize the path
$path = realpath($path);

// Security check - only allow browsing certain directories
$allowedBasePaths = [
    '/Users',
    '/Applications/MAMP',
    '/Applications'
];

$isAllowed = false;
foreach ($allowedBasePaths as $basePath) {
    if (strpos($path, $basePath) === 0) {
        $isAllowed = true;
        break;
    }
}

if (!$isAllowed) {
    echo json_encode([
        'error' => 'Access denied to this directory',
        'folders' => []
    ]);
    exit;
}

// Check if path exists and is readable
if (!$path || !is_dir($path) || !is_readable($path)) {
    echo json_encode([
        'error' => 'Directory not found or not accessible',
        'folders' => []
    ]);
    exit;
}

try {
    $folders = [];
    $items = scandir($path);
    
    if ($items === false) {
        throw new Exception('Cannot read directory');
    }
    
    foreach ($items as $item) {
        // Skip hidden files and current/parent directory entries
        if ($item[0] === '.' && $item !== '..') {
            continue;
        }
        
        if ($item === '.' || $item === '..') {
            continue;
        }
        
        $fullPath = $path . DIRECTORY_SEPARATOR . $item;
        
        // Only include directories
        if (is_dir($fullPath) && is_readable($fullPath)) {
            $folders[] = $item;
        }
    }
    
    // Sort folders alphabetically
    sort($folders);
    
    echo json_encode([
        'path' => $path,
        'folders' => $folders,
        'error' => null
    ]);
    
} catch (Exception $e) {
    echo json_encode([
        'error' => 'Error reading directory: ' . $e->getMessage(),
        'folders' => []
    ]);
}
?>
