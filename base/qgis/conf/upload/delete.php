<?php

function error(int $code = 500, string $message = ''): void
{
    echo $message;
    http_response_code($code);
    exit();
}

function pre($value): void
{
    echo '<pre>';
    print_r($value);
    echo '</pre>';
}

// exit(phpinfo());

// Ensure the path parameter is set.
$path = $_REQUEST['path'];
if (!isset($path)) {
    error(400, "Path not set.");
}

$base = '/fileport/qgisfiles';

// https://localhost:7443/qgisfiles/project-84507-1/qgisfiles/a_file.ext
$path = preg_replace('/^.*?\/qgisfiles\//', $base . '/', $path);
// /fileport/qgisfiles/project-84507-1/qgisfiles/a_file.ext
$path_parts = pathinfo($path);

if (! ($path_parts['dirname'] == $base || str_starts_with($path_parts['dirname'], $base . '/'))) {
    error(400, "Invalid path.");
}

if (! file_exists($path)) {
    error(404, "File/directory " . $path . " not found.");
}

function delete($path)
{
    if (!is_dir($path)) {
        return unlink($path);
    }

    foreach (scandir($path) as $item) {
        if ($item == '.' || $item == '..') {
            continue;
        }
        delete($path . DIRECTORY_SEPARATOR . $item);
    }

    return rmdir($path); // Delete the directory itself
}

if (! delete($path)) {
    error(500, "Failed to delete file/directory " . $path . ".");
}

$location = $_SERVER['HTTP_REFERER'];
// If the project folder was deleted, don't include the project query parameter.
if ($path_parts['dirname'] == $base) {
    $location = 'index.php';
}
header("Location: $location");
