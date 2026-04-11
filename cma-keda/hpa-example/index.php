<?php
// index.php

$x = 0.0001;
for ($i = 1; $i <= 10000000; $i++) {
    $x += sqrt($x);
}
echo "OK!";
?>