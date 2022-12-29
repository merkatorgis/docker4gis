<?php

function error(int $code = 500, string $message = ''): void
{
    echo $message;
    http_response_code($code);
    exit();
}

function command(string $command, array &$output = null, int &$result_code = null): string
{
    $result = exec($command, $output, $result_code);
    if ($result === false) {
        error(500, "Command failed: <pre>$command</pre> Output: <pre>$output</pre> Result code: <pre>$result_code</pre>");
    }
    return $result;
}

function pre($value): void
{
    echo '<pre>';
    print_r($value);
    echo '</pre>';
}

// $_FILES['file']
// Array
// (
//     [name] => Array
//         (
//             [0] => continents.dbf
//             [1] => continents.prj
//         )
//     [type] => Array
//         (
//             [0] => application/octet-stream
//             [1] => application/octet-stream
//         )
//     [tmp_name] => Array
//         (
//             [0] => /tmp/phpYtSJ4n
//             [1] => /tmp/phpHlwOro
//         )
//     [error] => Array
//         (
//             [0] => 0
//             [1] => 0
//         )
//     [size] => Array
//         (
//             [0] => 8356387
//             [1] => 143
//         )
// )
$file = $_FILES['file'];
$project = null;

// exit(phpinfo());

// Test if one of the files is a QGIS project file.
for ($i = 0; $i < count($file['name']); $i++) {

    $name = $file['name'][$i];

    $path_parts = pathinfo($name);

    $qgz = strcasecmp($path_parts['extension'], 'qgz') === 0;
    $isProject = $qgz || strcasecmp($path_parts['extension'], 'qgs') === 0;

    if ($isProject) {
        $project = $path_parts['filename'];
    }
}

// Ensure the project parameter is set.
$request_project = isset($_REQUEST['project']) ? $_REQUEST['project'] : null;
if (isset($project)) {
    if (isset($request_project) && $project !== $request_project) {
        error(400, "Project file name $project doesn't match project request parameter $request_project.");
    }
} else {
    $project = $request_project;
}
if (!isset($project)) {
    error(400, "Project not set.");
}

// Process each file.
for ($i = 0; $i < count($file['name']); $i++) {

    $name = $file['name'][$i];
    $tmp_name = $file['tmp_name'][$i];

    $path_parts = pathinfo($name);

    $qgz = strcasecmp($path_parts['extension'], 'qgz') === 0;
    $isProject = $qgz || strcasecmp($path_parts['extension'], 'qgs') === 0;

    $base = '/fileport';
    $dir = "/files/qgis/$project/";
    $full_dir = $base . $dir;
    $path = $dir . $path_parts['basename'];
    $full_path = $base . $path;

    file_exists($full_dir)
        || mkdir($full_dir, 0777, true);

    // echo '<pre>';
    // print_r($file);
    // echo '</pre>';
    // echo $tmp_name . ' ';
    // echo file_exists($tmp_name) ? 'exists' : "doesn't exist!";
    // echo '<br/>';

    // Save the file.
    move_uploaded_file($tmp_name, $full_path)
        || error(500, "Uploading file $path failed.");

    if ($qgz) {
        // Unzip .qgz file to .qgs file.
        // -o  overwrite files WITHOUT prompting
        // -d  extract files into exdir
        command("unzip -o '$full_path' -d '$full_dir'");
        $path = $dir . $project . '.qgs';
        $full_path = $base . $path;
    }

    if ($isProject) {
        // Copy the project file to use for the server.
        $server_path = "$full_path.server";
        command("cp '$full_path' '$server_path'");
        $full_path = $server_path;

        /*
        Replace layer source remote URLs with local file URLs.
        */

        // https://localhost:7443, https://www.geoloket.nl, etc.
        $origin = $_SERVER['HTTP_ORIGIN'];

        // Find all URLs that need manipulation.
        $pattern = "$origin.*$dir" . '[^"<]\+';
        // --only-matching to just get the matched text, instead of the whole line.
        $grep = "grep --only-matching '$pattern' '$full_path'";
        // https://localhost:7443/files/qgis/65521-1/1_04%20ZZW%20S5-2_IMG%20raster%201x1.img
        $urls = null;
        command($grep, $urls);

        // '1_04%20ZZW%20S5-2_IMG%20raster%201x1.img'
        $paths = preg_replace("|.*$dir(.*)|", '$1', $urls);
        // '1_04 ZZW S5-2_IMG raster 1x1.img' - It's only because we need to do
        // this, that we cannot just do one global sed for all URLs.
        $paths = array_map('urldecode', $paths);

        for ($j = 0; $j < count($urls); $j++) {
            // 'https://localhost:7443/files/qgis/65521-1/1_04%20ZZW%20S5-2_IMG%20raster%201x1.img'
            $search = $urls[$j];
            // '/fileport/files/qgis/65521-1/1_04 ZZW S5-2_IMG raster 1x1.img'
            $replace = $full_dir . $paths[$j];
            command("sed -i 's~$search~$replace~g' '$full_path'");
        }
    }
}

header("Location: index.php?project=$project");
