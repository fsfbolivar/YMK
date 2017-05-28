<!DOCTYPE html>
<html lang="en">
<head>
  <title>Bootstrap Example</title>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js"></script>
  <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>
</head>
<body>

<div class="container">
  <h2>Upload your file!</h2>
  <form method="POST" action="upload" enctype="multipart/form-data">
    <div class="form-group">
      <label for="file">File:</label>
      <input type="file" class="form-control" id="file" placeholder="Set file path" name="file">
    </div>
    <div class="form-group">
      <label for="destination">Destination:</label>
      <input type="text" class="form-control" id="destination" placeholder="Enter destination" name="destination" value="/home/ubuntu/uploaded-files">
    </div>
	<!-- <input type="submit" value="Upload" name="upload" id="upload" /> -->
    <button type="submit" class="btn btn-default">Upload</button>
  </form>
</div>

</body>
</html>