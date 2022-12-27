<html>

<head></head>

<body>
  <h4>File uploads</h4>
  <form enctype="multipart/form-data" action="upload.php" method="post">
    <p>
      Select File:
      <input type="file" size="35" name="uploadedfile" />
      <br />

      Destination <input type="text" size="35" name="destination" value="<?php echo "value"; ?>" />
      <br />
      <input type="submit" name="Upload" value="Upload" />
    </p>
  </form>
</body>

</html>