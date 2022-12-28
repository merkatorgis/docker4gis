<?php

// $_FILES['file']
// Array
// (
//     [name] => 65521-1.qgz
//     [type] => application/octet-stream
//     [tmp_name] => /tmp/php8HjLks
//     [error] => 0
//     [size] => 3987
// )
$file = $_FILES['file'];

$path_parts = pathinfo($file['name']);

if ($path_parts['extension'] == 'qgs' || $path_parts['extension'] == 'qgz') {
    $project = $path_parts['filename'];
} else {
    $project = $_REQUEST['project'];
}

$dir = "/fileport/files/qgis/$project/";
mkdir($dir, 0777, true);

$dest = $dir . $path_parts['basename'];

if (move_uploaded_file($file['tmp_name'], $dest)) {
    echo "The file $dest has been uploaded";
} else {
    echo "There was an error uploading the file, please try again!";
}
