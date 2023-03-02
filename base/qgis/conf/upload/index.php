<html>

<head>
  <style>
    body {
      overflow: hidden;
      margin: 1em;
    }

    h1 {
      height: 30px;
      margin: 0;
    }

    #box {
      display: flex;
      margin-top: 1em;
      height: calc(100% - 30px - 1em);
    }

    nav {
      flex-grow: 1;
      padding-left: 1em;
    }

    label>input {
      width: 100%;
      max-width: 20em;
      margin-top: .25em;
    }
  </style>
</head>

<?php $project = isset($_REQUEST['project']) ? $_REQUEST['project'] : ''; ?>

<body>

  <h1>Upload files to QGIS Server</h1>

  <div id="box">

    <div>
      <form enctype="multipart/form-data" action="upload.php" method="post">
        <p>
          <label>
            Select file *<br />
            <input type="file" name="file[]" id="file" required multiple />
          </label>
        </p>

        <p>
          <label>
            Project (if not .qgs)<br />
            <input type="text" name="project" id="project" value="<?= $project ?>" />
          </label>
        </p>

        <p>
          <input type="submit" name="upload" id="upload" value="Upload" />
        </p>
      </form>

      <script>
        file.addEventListener('change', () => {
          project.disabled = file.value.endsWith('qgs') || file.value.endsWith('qgz');
        });
      </script>
    </div>

    <nav>
      <iframe id="iframe" width="100%" height="100%" src="../files/qgis/<?= $project ?>">
      </iframe>
    </nav>

  </div>

</body>

</html>