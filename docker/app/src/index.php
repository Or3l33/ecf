<?php
// Page de test : version de l'application, environnement PHP, connexion MySQL et compteur de visites
header('Content-Type: text/plain; charset=utf-8');
ob_start(); // retient l'affichage pour pouvoir encore renvoyer le code HTTP 500 en cas d'erreur

echo "Application : " . getenv('APP_VERSION') . "\n";
echo "PHP : " . PHP_VERSION . "\n";
echo "Extensions : " . implode(', ', array_filter(
    ['pdo_mysql', 'mysqli', 'gd', 'zip'],
    'extension_loaded'
)) . "\n";

try {
    $pdo = new PDO(
        sprintf('mysql:host=%s;dbname=%s', getenv('DB_HOST'), getenv('DB_NAME')),
        getenv('DB_USER'),
        getenv('DB_PASSWORD')
    );
    $version = $pdo->query('SELECT VERSION()')->fetchColumn();
    echo "MySQL : connexion OK (serveur " . getenv('DB_HOST') . ", version $version)\n";

    // Fonctionnalité v2 : compteur de visites stocké dans MySQL
    $pdo->exec('CREATE TABLE IF NOT EXISTS visites (id INT PRIMARY KEY, total INT NOT NULL)');
    $pdo->exec('INSERT INTO visites VALUES (1, 1) ON DUPLICATE KEY UPDATE total = total + 1');
    $total = $pdo->query('SELECT total FROM visites WHERE id = 1')->fetchColumn();
    echo "Visites : $total\n";
} catch (PDOException $e) {
    http_response_code(500);
    echo "MySQL : ERREUR de connexion - " . $e->getMessage() . "\n";
}
