<?php
session_start();
require '../../config.php';

if (!isset($_SESSION['user_id'])) {
    header("Location: ../../profil/login.php");
    exit;
}
?>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Taverne Municipale</title>

<style>
body {
    margin: 0;
    font-family: Georgia, serif;
    color: #e0d3a3;

    background: url('../../assets/taverne.jpg') no-repeat center center fixed;
    background-size: cover;
    height: 100vh;
}

body::before {
    content: "";
    position: fixed;
    inset: 0;
    background: rgba(0,0,0,0.6);
    z-index: 0;
}

.container {
    position: relative;
    z-index: 2;
    max-width: 900px;
    margin: 80px auto;
}

h1 {
    text-align: center;
    color: #d4af37;
}

.chat {
    background: rgba(20,10,5,0.85);
    border: 2px solid #d4af37;
    padding: 20px;
    height: 400px;
    overflow-y: auto;
}

.msg {
    margin-bottom: 10px;
}

.user {
    color: #d4af37;
    font-weight: bold;
}

form {
    margin-top: 10px;
    text-align: center;
}

input {
    width: 70%;
    padding: 10px;
    background: #111;
    color: white;
    border: 1px solid #d4af37;
}

button {
    padding: 10px;
    background: transparent;
    color: #d4af37;
    border: 1px solid #d4af37;
    cursor: pointer;
}

button:hover {
    background: #d4af37;
    color: black;
}

.back {
    display: block;
    text-align: center;
    margin-top: 15px;
    color: #aaa;
}
</style>
</head>

<body>

<div class="container">

    <h1>🍺 Taverne Municipale de Rouen</h1>

    <div class="chat" id="chat"></div>

    <form id="form">
        <input type="text" name="message" id="message" placeholder="Dire quelque chose..." autocomplete="off">
        <button type="submit">Envoyer</button>
    </form>

    <a href="index.php" class="back">← Retour aux tavernes</a>

</div>

<!-- JS DOIT ÊTRE ICI -->
<script>
function loadMessages() {
    fetch("fetch.php")
        .then(res => res.text())
        .then(data => {
            let chat = document.getElementById("chat");
            chat.innerHTML = data;

            // auto scroll
            chat.scrollTop = chat.scrollHeight;
        });
}

// refresh auto
setInterval(loadMessages, 2000);
loadMessages();

// envoyer message
document.getElementById("form").addEventListener("submit", function(e) {
    e.preventDefault();

    let formData = new FormData(this);

    fetch("send.php", {
        method: "POST",
        body: formData
    }).then(() => {
        document.getElementById("message").value = "";
        loadMessages();
    });
});
</script>

</body>
</html>