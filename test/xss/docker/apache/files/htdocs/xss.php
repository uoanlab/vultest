<html>
<body>
    <form action="" method="post" accept-charset="utf-8">
        <input type="text" name="xss_text" value="">
        <p><input type="submit" value="submit"></p>
    </form>
    value: <?php echo $_POST['xss_text']; ?>
</body>
</html>
