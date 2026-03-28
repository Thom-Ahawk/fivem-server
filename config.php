<?php
$host = 'db5020106191.hosting-data.io';
$dbname = 'dbs15490106';
$user = 'dbu3042399';
$pass = 'Atcryky76!';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (Exception $e) {
    echo $e->getMessage();
exit;
}
?>