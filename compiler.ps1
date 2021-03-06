# le nom du dossier pour chrome
$plugin = 'raid_facile'
# le nom du dossier où seront mis les fichiers à uploader
$uploadDir = 'upload'
# le nom du dossier où seront mis les fichiers pour l'extension chrome non empaquetée
$betaDir = 'beta'


### Préparation fichiers et dossier ###
function preparation {
    if (Test-Path $uploadDir) { rmdir $uploadDir -Recurse }
    mkdir $uploadDir | Out-Null
    if (Test-Path $plugin) { rmdir $plugin -Recurse }
    mkdir $plugin | Out-Null
    copy .\icon16.png $plugin
    copy .\icon48.png $plugin
    copy .\icon128.png $plugin
    copy .\manifest.json $plugin
    copy .\js $plugin -Recurse
    echo '--- Préparation ok ---'
}

### Compression et compilation ###
function compilationFichier([string]$nom) {
    $compilation_level = "SIMPLE_OPTIMIZATIONS"
    $compilation_level = "WHITESPACE_ONLY"
    java -jar closureCompiler\compiler.jar --compilation_level $compilation_level --js "$plugin\js\$nom.js" --js_output_file "$plugin\js\$nom compiled.js"
    move "$plugin\js\$nom compiled.js" "$plugin\js\$nom.js" -Force
}
function supprimerBOM([string]$chemin) {
    # Supression du BOM utf8
    $contenu = cat "$chemin" -Encoding utf8
    [System.IO.File]::WriteAllLines("$chemin", $contenu)
}
function compilation([bool]$compiler) {
    if ($compiler) {
        if (Test-Path closureCompiler\compiler.jar) {
            compilationFichier "$plugin 1"
            compilationFichier "$plugin injected"
        } else {
            echo '--- Compilation erreur : "compiler.jar" n`est pas dans le dossier "closureCompiler" ---'
        }
    }

    if ($compiler) {
        echo "--- Compilation ok ---"
    } else {
        echo "--- Compilation(ignorée) ok ---"
    }
}

### Fichier .user.js ###
function userjs {
    $JsDestination = "$uploadDir\$plugin.user.js"
    echo $null > $jsDestination
    cat ".\userscript.header.js" -Encoding utf8 | Out-File $jsDestination -Encoding utf8 -Append
    cat "$plugin\js\$plugin 1.js" -Encoding utf8 | Out-File $jsDestination -Encoding utf8 -Append
    cat "$plugin\js\$plugin 2.js" -Encoding utf8 | Out-File $jsDestination -Encoding utf8 -Append
    cat "$plugin\js\$plugin injected.js" -Encoding utf8 | Out-File $jsDestination -Encoding utf8 -Append
    supprimerBOM $jsDestination
    copy "userscript.header.js" $uploadDir
    echo "--- .user.js ok ---"
}

### Fichier .crx ###
function crx {
    # Création du package .crx
    $chrome = $env:LOCALAPPDATA+"\Google\Chrome\Application\chrome.exe"
    if (Test-Path ($plugin+".pem")) {
        $chromeArgs = '--pack-extension="'+$PWD+'\'+$plugin+'"', '--pack-extension-key="'+$PWD+'\'+$plugin+'.pem"'
    } else {
        $chromeArgs = '--pack-extension="'+$PWD+'\'+$plugin+'"'
    }
    Start-Process $chrome -ArgumentList $chromeArgs -NoNewWindow -Wait
    move $plugin".crx" $uploadDir
}

### Dossier beta ###
function beta {
    if (Test-Path $betaDir) { rmdir $betaDir -Recurse }
    copy -Recurse $plugin $betaDir
    echo "--- beta ok ---"
}

### Nettoyage ###
function nettoyage {
    if (Test-Path $plugin) { rmdir $plugin -Recurse }
    echo "--- Nettoyage ok ---"
}

### code source ###
function codesource {
    $dossier = $plugin+' - sources'
    $fichiers = 'compiler.ps1', 'icon16.png', 'icon48.png', 'icon128.png', 'Instructions.txt', 'manifest.json', 'userscript.header.js'
    mkdir $dossier | Out-Null
    mkdir $dossier\closureCompiler | Out-Null
    copy -Path $fichiers -Destination $dossier
    copy -Path 'js' -Destination $dossier -Recurse
    $rarArgs = 'm "'+$uploadDir+'\'+$dossier+'" "'+$dossier+'"'
    Start-Process $env:ProgramFiles"\WinRAR\Rar.exe" -ArgumentList $rarArgs -NoNewWindow -Wait
    echo "--- Code source ok ---"
}

$compress = $false
$compress = $true

preparation;
compilation $compress;
userjs;
#crx;
beta;
nettoyage
