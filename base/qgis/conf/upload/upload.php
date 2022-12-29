<?php

function error($code = 500, $message = '')
{
    echo $message;
    http_response_code($code);
    exit();
}

function command($command)
{
    if (exec($command) === false) {
        error(500, "Command failed: <pre>$command</pre>");
    }
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

for ($i = 0; $i < count($file['name']); $i++) {

    $name = $file['name'][$i];

    $path_parts = pathinfo($name);

    $qgz = strcasecmp($path_parts['extension'], 'qgz') === 0;
    $isProject = $qgz || strcasecmp($path_parts['extension'], 'qgs') === 0;

    if ($isProject) {
        $project = $path_parts['filename'];
    }
}

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
        // Replace layer source URLs with local paths.
        // https://localhost:7443, https://www.geoloket.nl, etc.
        $origin = $_SERVER['HTTP_ORIGIN'];
        command("sed -i 's~$origin.*$dir~file://$full_dir~g' '$full_path'");
    }
}

header("Location: index.php?project=$project");
