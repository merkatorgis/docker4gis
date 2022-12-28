<?php

function error($code = 500, $message = '')
{
    echo $message;
    http_response_code($code);
    exit();
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
$project = $_REQUEST['project'];

// exit(phpinfo());

for ($i = 0; $i < count($file['name']); $i++) {

    $name = $file['name'][$i];
    $tmp_name = $file['tmp_name'][$i];

    $path_parts = pathinfo($name);

    $qgz = strcasecmp($path_parts['extension'], 'qgz') === 0;
    $isProject = $qgz || strcasecmp($path_parts['extension'], 'qgs') === 0;

    if ($isProject) {
        $project = $path_parts['filename'];
    }

    if (!isset($project)) {
        error(400, "Project not set.");
    }

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
        exec("unzip '$full_path' -d '$full_dir'")
            || error(500, "Unzipping file $path failed.");
    }
}

header("Location: index.php?project=$project");
