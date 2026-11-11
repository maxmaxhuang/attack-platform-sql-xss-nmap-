<?php
declare(strict_types=1);

/**
 * PHP 内置服务器路由
 *
 *   http://host:port/                  -> 302 -> /matrix-login/
 *   http://host:port/matrix-login/...  -> matrix-login 目录内文件
 *   其他路径                            -> 404
 *
 * 这样无论访问根路径还是 /matrix-login/，都不会再出现路径型 404。
 */

$uri = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);
$uri = is_string($uri) ? rawurldecode($uri) : '/';
$base = '/matrix-login';

if ($uri === '/' || $uri === '' || $uri === $base) {
    header('Location: ' . $base . '/');
    exit;
}

if (strpos($uri, $base . '/') !== 0) {
    http_response_code(404);
    header('Content-Type: text/plain; charset=utf-8');
    echo "404 — only /matrix-login/ is served here\n";
    return true;
}

$relative = substr($uri, strlen($base));
$baseDir = realpath(__DIR__ . '/matrix-login');
$target = realpath(__DIR__ . '/matrix-login' . $relative);

if ($baseDir === false || $target === false) {
    http_response_code(404);
    echo "404\n";
    return true;
}

if ($target !== $baseDir && strpos($target, $baseDir . DIRECTORY_SEPARATOR) !== 0) {
    http_response_code(403);
    echo "403\n";
    return true;
}

if (is_dir($target)) {
    $target = realpath($target . DIRECTORY_SEPARATOR . 'index.php');
}

if ($target === false || !is_file($target)) {
    http_response_code(404);
    echo "404\n";
    return true;
}

if (strtolower(pathinfo($target, PATHINFO_EXTENSION)) === 'php') {
    require $target;
    return true;
}

$mime = [
    'css'   => 'text/css; charset=utf-8',
    'js'    => 'application/javascript; charset=utf-8',
    'mjs'   => 'application/javascript; charset=utf-8',
    'json'  => 'application/json; charset=utf-8',
    'svg'   => 'image/svg+xml',
    'png'   => 'image/png',
    'jpg'   => 'image/jpeg',
    'jpeg'  => 'image/jpeg',
    'gif'   => 'image/gif',
    'ico'   => 'image/x-icon',
    'woff'  => 'font/woff',
    'woff2' => 'font/woff2',
    'ttf'   => 'font/ttf',
    'txt'   => 'text/plain; charset=utf-8',
];

$extension = strtolower(pathinfo($target, PATHINFO_EXTENSION));
header('Content-Type: ' . ($mime[$extension] ?? 'application/octet-stream'));
header('Content-Length: ' . filesize($target));
readfile($target);
return true;
