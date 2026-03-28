<?php
session_start();
require '../../config.php';

if (!isset($_SESSION['user_id'])) exit;

$msg = trim($_POST['message']);

if (!empty($msg)) {
    $stmt = $pdo->prepare("INSERT INTO taverne (user_id, message) VALUES (?, ?)");
    $stmt->execute([$_SESSION['user_id'], $msg]);
}