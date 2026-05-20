#!/bin/bash

# ============================================
# DOC -> PDF CONVERTER + WEB VIEWER
# ============================================

# === ПЕРЕМЕННЫЕ ===
SRC_DIR="/var/www/portfolio/doc_source"
IN_DIR="/var/www/portfolio/doc_in"
PDF_DIR="/var/www/portfolio/pdf"
ARCH_DIR="/var/www/portfolio/arhiv/files_doc_out"
BASE_DIR="/var/www/portfolio"
LOG_FILE="/var/www/portfolio/process_doc.log"

# ============================================
# ОЧИСТКА ЛОГА
# ============================================

echo "=== DOC TO PDF PROCESSING LOG ===" > "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# ============================================
# СОЗДАНИЕ КАТАЛОГОВ
# ============================================

echo "Creating directories..."

sudo mkdir -p "$SRC_DIR"
sudo mkdir -p "$IN_DIR"
sudo mkdir -p "$PDF_DIR"
sudo mkdir -p "$ARCH_DIR"

# ============================================
# УСТАНОВКА ПРОГРАММ
# ============================================

echo "Installing programs..."

sudo apt update

sudo apt install -y \
    libreoffice \
    unoconv \
    apache2 \
    tar \
    bzip2 \
    zip

sudo systemctl enable apache2
sudo systemctl start apache2

# ============================================
# КОПИРОВАНИЕ DOC ФАЙЛОВ
# ============================================

echo "Copying DOC files..."

if [ ! -d "$SRC_DIR" ]; then
    mkdir -p "$SRC_DIR"
    echo "Put DOC files into $SRC_DIR" | tee -a "$LOG_FILE"
    exit 1
fi

FOUND_DOC=0

for doc in "$SRC_DIR"/*.doc "$SRC_DIR"/*.docx; do
    if [ -f "$doc" ]; then
        FOUND_DOC=1
        sudo cp "$doc" "$IN_DIR/"
        echo "Copied: $(basename "$doc")" >> "$LOG_FILE"
    fi
done

if [ $FOUND_DOC -eq 0 ]; then
    echo "No DOC/DOCX files found in $SRC_DIR"
    exit 1
fi

# ============================================
# КОНВЕРТАЦИЯ DOC -> PDF
# ============================================

echo "Converting DOC files to PDF..."

for doc in "$IN_DIR"/*.doc "$IN_DIR"/*.docx; do

    [ -f "$doc" ] || continue

    filename=$(basename "$doc")

    echo "Processing: $filename" >> "$LOG_FILE"

    libreoffice \
        --headless \
        --convert-to pdf \
        --outdir "$PDF_DIR" \
        "$doc"

    echo "Converted: $filename" >> "$LOG_FILE"

done

# ============================================
# АРХИВАЦИЯ DOC ФАЙЛОВ
# ============================================

echo "Creating archive..."

ARCHIVE_NAME="files_doc_out_$(date +%Y%m%d_%H%M%S).tar.bz2"

sudo tar -cjf \
    "$ARCH_DIR/$ARCHIVE_NAME" \
    -C "$IN_DIR" .

echo "Archive created: $ARCHIVE_NAME" >> "$LOG_FILE"

# ============================================
# СОЗДАНИЕ ZIP АРХИВА
# ============================================

ZIP_NAME="doc_reports_$(date +%Y%m%d_%H%M%S).zip"

cd "$BASE_DIR"

zip -r "$ZIP_NAME" \
    doc_in \
    pdf \
    *.html \
    process_doc.log

echo "ZIP created: $ZIP_NAME" >> "$LOG_FILE"

# ============================================
# СОЗДАНИЕ СТРАНИЦЫ DOC
# ============================================

cat > "$BASE_DIR/word_original.html" << 'EOF'
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DOC Документы</title>

    <link rel="stylesheet" href="styles.css">
    <link rel="stylesheet" href="main.css">

    <style>

        body {
            overflow: hidden;
        }

        .layout {
            display: flex;
            margin-top: 90px;
            height: calc(100vh - 90px);
        }

        .sidebar {
            width: 320px;
            background: rgba(255,255,255,0.05);
            border-right: 1px solid rgba(255,255,255,0.1);
            overflow-y: auto;
            padding: 20px;
        }

        .sidebar h2 {
            color: var(--brand-main);
            margin-bottom: 20px;
        }

        .doc-item {
            background: rgba(255,255,255,0.05);
            border-radius: 10px;
            padding: 15px;
            margin-bottom: 15px;
            cursor: pointer;
            transition: 0.3s;
        }

        .doc-item:hover {
            background: rgba(255,255,255,0.12);
            transform: translateX(5px);
        }

        .doc-item h3 {
            color: var(--brand-main);
            font-size: 15px;
            word-break: break-all;
            margin-bottom: 8px;
        }

        .doc-item p {
            color: var(--text-gray);
            font-size: 13px;
        }

        .viewer {
            flex: 1;
            background: rgba(255,255,255,0.03);
        }

        iframe {
            width: 100%;
            height: 100%;
            border: none;
            background: white;
        }

    </style>
</head>
<body>

<div class="hero-bg">
    <div class="stars"></div>
</div>

<header>

    <div class="a_box">
        <a href="./index.html">Обо мне</a>
        <div class="a_box_line"></div>
    </div>

    <div class="a_box">
        <a href="./projects/projects.html">Проекты</a>
        <div class="a_box_line"></div>
    </div>

    <div class="a_box">
        <a href="./contacts/contacts.html">Контакты</a>
        <div class="a_box_line"></div>
    </div>

    <div class="a_box">
        <a href="./word_original.html">DOC</a>
        <div class="a_box_line"></div>
    </div>

    <div class="a_box">
        <a href="./word_processed.html">PDF</a>
        <div class="a_box_line"></div>
    </div>

</header>

<div class="layout">

    <div class="sidebar">

        <h2>DOC Файлы</h2>

EOF

FIRST_DOC=""

for doc in "$IN_DIR"/*.doc "$IN_DIR"/*.docx; do

    [ -f "$doc" ] || continue

    filename=$(basename "$doc")

    if [ -z "$FIRST_DOC" ]; then
        FIRST_DOC="$filename"
    fi

    size=$(stat -c%s "$doc")
    size_mb=$(awk "BEGIN {printf \"%.2f\", $size/1048576}")

cat >> "$BASE_DIR/word_original.html" << EOF

        <div class="doc-item"
             onclick="openDoc('https://view.officeapps.live.com/op/embed.aspx?src=http://$(hostname -I | awk '{print $1}')/doc_in/$filename')">

            <h3>$filename</h3>
            <p>${size_mb} MB</p>

            <a href="./doc_in/$filename" download
               style="color: #4ecdc4;">
               Скачать DOC
            </a>

        </div>

EOF

done

cat >> "$BASE_DIR/word_original.html" << EOF

    </div>

    <div class="viewer">

        <iframe id="viewerFrame"
            src="https://view.officeapps.live.com/op/embed.aspx?src=http://$(hostname -I | awk '{print $1}')/doc_in/$FIRST_DOC">
        </iframe>

    </div>

</div>

<script>

function openDoc(url) {
    document.getElementById("viewerFrame").src = url;
}

</script>

<script src="main.js"></script>
<script src="stars.js"></script>

</body>
</html>

EOF

# ============================================
# СОЗДАНИЕ СТРАНИЦЫ PDF
# ============================================

cat > "$BASE_DIR/word_processed.html" << 'EOF'
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PDF Документы</title>

    <link rel="stylesheet" href="styles.css">
    <link rel="stylesheet" href="main.css">

    <style>

        body {
            overflow: hidden;
        }

        .layout {
            display: flex;
            margin-top: 90px;
            height: calc(100vh - 90px);
        }

        .sidebar {
            width: 320px;
            background: rgba(255,255,255,0.05);
            border-right: 1px solid rgba(255,255,255,0.1);
            overflow-y: auto;
            padding: 20px;
        }

        .sidebar h2 {
            color: var(--brand-main);
            margin-bottom: 20px;
        }

        .pdf-item {
            background: rgba(255,255,255,0.05);
            border-radius: 10px;
            padding: 15px;
            margin-bottom: 15px;
            cursor: pointer;
            transition: 0.3s;
        }

        .pdf-item:hover {
            background: rgba(255,255,255,0.12);
            transform: translateX(5px);
        }

        .pdf-item h3 {
            color: var(--brand-main);
            font-size: 15px;
            word-break: break-all;
            margin-bottom: 8px;
        }

        .pdf-item p {
            color: var(--text-gray);
            font-size: 13px;
        }

        .viewer {
            flex: 1;
            background: rgba(255,255,255,0.03);
        }

        iframe {
            width: 100%;
            height: 100%;
            border: none;
            background: white;
        }

    </style>
</head>
<body>

<div class="hero-bg">
    <div class="stars"></div>
</div>

<header>

    <div class="a_box">
        <a href="./index.html">Обо мне</a>
        <div class="a_box_line"></div>
    </div>

    <div class="a_box">
        <a href="./projects/projects.html">Проекты</a>
        <div class="a_box_line"></div>
    </div>

    <div class="a_box">
        <a href="./contacts/contacts.html">Контакты</a>
        <div class="a_box_line"></div>
    </div>

    <div class="a_box">
        <a href="./word_original.html">DOC</a>
        <div class="a_box_line"></div>
    </div>

    <div class="a_box">
        <a href="./word_processed.html">PDF</a>
        <div class="a_box_line"></div>
    </div>

</header>

<div class="layout">

    <div class="sidebar">

        <h2>PDF Файлы</h2>

EOF

FIRST_PDF=""

for pdf in "$PDF_DIR"/*.pdf; do

    [ -f "$pdf" ] || continue

    filename=$(basename "$pdf")

    if [ -z "$FIRST_PDF" ]; then
        FIRST_PDF="$filename"
    fi

    size=$(stat -c%s "$pdf")
    size_mb=$(awk "BEGIN {printf \"%.2f\", $size/1048576}")

cat >> "$BASE_DIR/word_processed.html" << EOF

        <div class="pdf-item"
             onclick="openPDF('./pdf/$filename')">

            <h3>$filename</h3>
            <p>${size_mb} MB</p>

            <a href="./pdf/$filename" download
               style="color: #ff6b6b;">
               Скачать PDF
            </a>

        </div>

EOF

done

cat >> "$BASE_DIR/word_processed.html" << EOF

    </div>

    <div class="viewer">

        <iframe id="pdfFrame"
            src="./pdf/$FIRST_PDF">
        </iframe>

    </div>

</div>

<script>

function openPDF(url) {
    document.getElementById("pdfFrame").src = url;
}

</script>

<script src="main.js"></script>
<script src="stars.js"></script>

</body>
</html>

EOF

# ============================================
# ПРАВА
# ============================================

sudo chown -R www-data:www-data "$BASE_DIR"
sudo chmod -R 755 "$BASE_DIR"

# ============================================
# ЗАВЕРШЕНИЕ
# ============================================

echo ""
echo "============================================"
echo "DONE!"
echo "============================================"
echo ""

echo "Website:"
echo "http://$(hostname -I | awk '{print $1}')/word_original.html"

echo ""
echo "PDF page:"
echo "http://$(hostname -I | awk '{print $1}')/word_processed.html"

echo ""
echo "Archive:"
echo "$ARCH_DIR/$ARCHIVE_NAME"

echo ""
echo "ZIP:"
echo "$BASE_DIR/$ZIP_NAME"

echo ""
echo "Log file:"
echo "$LOG_FILE"