<?php
require '../../config.php';

$messages = $pdo->query("
    SELECT taverne.*, users.username 
    FROM taverne 
    JOIN users ON users.id = taverne.user_id 
    ORDER BY taverne.id DESC 
    LIMIT 40
")->fetchAll();

foreach ($messages as $m) {
    echo "<div class='msg'>";
    echo "<span class='user'>" . htmlspecialchars($m['username']) . " :</span> ";
    echo htmlspecialchars($m['message']);
    echo "</div>";
}