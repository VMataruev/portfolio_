#!/bin/bash

# ============================================
# WORD DOC/DOCX -> PDF + WEBSITE VIEWER
# ============================================

# ========= ПЕРЕМЕННЫЕ =========

SRC_DIR="/var/www/portfolio/doc_source"
IN_DIR="/var/www/portfolio/doc_in"
PDF_DIR="/var/www/portfolio/pdf"
ARCH_DIR="/var/www/portfolio/arhiv/files_doc_out"

BASE_DIR="/var/www/portfolio"

LOG_FILE="/var/www/portfolio/process_doc.log"

SERVER_IP=$(hostname -I | awk '{print $1}')

# ============================================
# ЛОГ
# ============================================

echo "=== DOC PROCESSING LOG ===" > "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# ============================================
# СОЗДАНИЕ ПАПОК
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
    libreoffice-writer \
    apache2 \
    tar \
    bzip2 \
    zip

sudo systemctl enable apache2
sudo systemctl start apache2

# ============================================
# КОПИРОВАНИЕ DOC
# ============================================

echo "Copying DOC files..."

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
# АРХИВАЦИЯ TAR.BZ2
# ============================================

echo "Creating TAR.BZ2 archive..."

ARCHIVE_NAME="files_doc_out_$(date +%Y%m%d_%H%M%S).tar.bz2"

sudo tar -cjf \
    "$ARCH_DIR/$ARCHIVE_NAME" \
    -C "$IN_DIR" .

# ============================================
# ZIP АРХИВ
# ============================================

echo "Creating ZIP archive..."

ZIP_NAME="word_project_$(date +%Y%m%d_%H%M%S).zip"

cd "$BASE_DIR"

zip -r "$ZIP_NAME" \
    doc_in \
    pdf \
    *.html \
    process_doc.log

# ============================================
# WORD ORIGINAL PAGE
# ============================================

cat > "$BASE_DIR/word_original.html" << EOF
<!DOCTYPE html>
<html lang="ru">
<head>

    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>WORD | Оригиналы</title>

    <link rel="stylesheet" href="styles.css">
    <link rel="stylesheet" href="main.css">

    <style>

        body {
            overflow: hidden;
        }

        .documents_layout {
            display: flex;
            width: 100%;
            height: 100svh;
            padding-top: 140px;
            color: var(--text-main);
        }

        .sidebar {

            width: 350px;
            min-width: 350px;

            height: calc(100svh - 140px);

            background: rgba(255,255,255,0.03);

            backdrop-filter: blur(20px);

            border-right: 1px solid rgba(255,255,255,0.08);

            overflow-y: auto;

            padding: 30px;
        }

        .sidebar_title {

            color: var(--brand-main);

            font-size: 32px;

            margin-bottom: 30px;
        }

        .doc_card {

            background: rgba(255,255,255,0.04);

            border: 1px solid rgba(255,255,255,0.06);

            border-radius: 15px;

            padding: 18px;

            margin-bottom: 20px;

            cursor: pointer;

            transition: .4s;
        }

        .doc_card:hover {

            transform: translateX(8px);

            background: rgba(255,255,255,0.08);
        }

        .doc_card h3 {

            color: var(--brand-main);

            font-size: 18px;

            margin-bottom: 10px;

            word-break: break-all;
        }

        .doc_card p {

            color: var(--text-gray);

            margin-bottom: 15px;
        }

        .download_btn {

            border: 1px solid var(--brand-main);

            display: inline-flex;

            justify-content: center;

            align-items: center;

            padding: 8px 16px;

            border-radius: 5px 5px 15px 5px;

            color: var(--text-gray);

            text-decoration: none;

            transition: .4s;
        }

        .download_btn:hover {

            background-color: var(--brand-main);

            color: black;
        }

        .viewer {

            flex: 1;

            height: calc(100svh - 140px);

            padding: 20px;
        }

        .viewer iframe {

            width: 100%;

            height: 100%;

            border: none;

            border-radius: 20px;

            background: white;
        }

    </style>

</head>

<body>

<div class="hero-bg">
    <div class="stars"></div>
</div>

<div class="wrapper_main">

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

    <div class="dropbox">

        <div class="dropbox_title">Больше</div>

        <div class="dropbox_box">

            <div class="a_box">
                <a href="./foto_original.html">ФОТО | Оригиналы</a>
                <div class="a_box_line"></div>
            </div>

            <div class="a_box">
                <a href="./foto_processed.html">ФОТО | Обработанные</a>
                <div class="a_box_line"></div>
            </div>

            <div class="a_box">
                <a href="./video_original.html">ВИДЕО | Оригиналы</a>
                <div class="a_box_line"></div>
            </div>

            <div class="a_box">
                <a href="./video_processed.html">ВИДЕО | Обработанные</a>
                <div class="a_box_line"></div>
            </div>

            <div class="a_box">
                <a href="./word_original.html">WORD | Оригиналы</a>
                <div class="a_box_line"></div>
            </div>

            <div class="a_box">
                <a href="./word_processed.html">WORD | Обработанные</a>
                <div class="a_box_line"></div>
            </div>

        </div>

    </div>

</header>

<div class="documents_layout">

<div class="sidebar">

<div class="sidebar_title">
DOC / DOCX
</div>

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

<div class="doc_card"
onclick="openDoc('https://view.officeapps.live.com/op/embed.aspx?src=http://$SERVER_IP/doc_in/$filename')">

    <h3>$filename</h3>

    <p>${size_mb} MB</p>

    <a class="download_btn"
       href="./doc_in/$filename"
       download>

       Скачать DOC

    </a>

</div>

EOF

done

cat >> "$BASE_DIR/word_original.html" << EOF

</div>

<div class="viewer">

<iframe id="viewerFrame"
src="https://view.officeapps.live.com/op/embed.aspx?src=http://$SERVER_IP/doc_in/$FIRST_DOC">
</iframe>

</div>

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
# WORD PROCESSED PAGE
# ============================================

cat > "$BASE_DIR/word_processed.html" << EOF
<!DOCTYPE html>
<html lang="ru">
<head>

    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>WORD | PDF</title>

    <link rel="stylesheet" href="styles.css">
    <link rel="stylesheet" href="main.css">

    <style>

        body {
            overflow: hidden;
        }

        .documents_layout {
            display: flex;
            width: 100%;
            height: 100svh;
            padding-top: 140px;
            color: var(--text-main);
        }

        .sidebar {

            width: 350px;
            min-width: 350px;

            height: calc(100svh - 140px);

            background: rgba(255,255,255,0.03);

            backdrop-filter: blur(20px);

            border-right: 1px solid rgba(255,255,255,0.08);

            overflow-y: auto;

            padding: 30px;
        }

        .sidebar_title {

            color: var(--brand-main);

            font-size: 32px;

            margin-bottom: 30px;
        }

        .doc_card {

            background: rgba(255,255,255,0.04);

            border: 1px solid rgba(255,255,255,0.06);

            border-radius: 15px;

            padding: 18px;

            margin-bottom: 20px;

            cursor: pointer;

            transition: .4s;
        }

        .doc_card:hover {

            transform: translateX(8px);

            background: rgba(255,255,255,0.08);
        }

        .doc_card h3 {

            color: var(--brand-main);

            font-size: 18px;

            margin-bottom: 10px;

            word-break: break-all;
        }

        .doc_card p {

            color: var(--text-gray);

            margin-bottom: 15px;
        }

        .download_btn {

            border: 1px solid var(--brand-main);

            display: inline-flex;

            justify-content: center;

            align-items: center;

            padding: 8px 16px;

            border-radius: 5px 5px 15px 5px;

            color: var(--text-gray);

            text-decoration: none;

            transition: .4s;
        }

        .download_btn:hover {

            background-color: var(--brand-main);

            color: black;
        }

        .viewer {

            flex: 1;

            height: calc(100svh - 140px);

            padding: 20px;
        }

        .viewer iframe {

            width: 100%;

            height: 100%;

            border: none;

            border-radius: 20px;

            background: white;
        }

    </style>

</head>

<body>

<div class="hero-bg">
    <div class="stars"></div>
</div>

<div class="wrapper_main">

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

    <div class="dropbox">

        <div class="dropbox_title">Больше</div>

        <div class="dropbox_box">

            <div class="a_box">
                <a href="./foto_original.html">ФОТО | Оригиналы</a>
                <div class="a_box_line"></div>
            </div>

            <div class="a_box">
                <a href="./foto_processed.html">ФОТО | Обработанные</a>
                <div class="a_box_line"></div>
            </div>

            <div class="a_box">
                <a href="./video_original.html">ВИДЕО | Оригиналы</a>
                <div class="a_box_line"></div>
            </div>

            <div class="a_box">
                <a href="./video_processed.html">ВИДЕО | Обработанные</a>
                <div class="a_box_line"></div>
            </div>

            <div class="a_box">
                <a href="./word_original.html">WORD | Оригиналы</a>
                <div class="a_box_line"></div>
            </div>

            <div class="a_box">
                <a href="./word_processed.html">WORD | Обработанные</a>
                <div class="a_box_line"></div>
            </div>

        </div>

    </div>

</header>

<div class="documents_layout">

<div class="sidebar">

<div class="sidebar_title">
PDF DOCUMENTS
</div>

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

<div class="doc_card"
onclick="openPDF('./pdf/$filename')">

    <h3>$filename</h3>

    <p>${size_mb} MB</p>

    <a class="download_btn"
       href="./pdf/$filename"
       download>

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
# ГОТОВО
# ============================================

echo ""
echo "===================================="
echo "DONE!"
echo "===================================="

echo ""
echo "WORD ORIGINAL:"
echo "http://$SERVER_IP/word_original.html"

echo ""
echo "WORD PDF:"
echo "http://$SERVER_IP/word_processed.html"

echo ""
echo "ARCHIVE:"
echo "$ARCH_DIR/$ARCHIVE_NAME"

echo ""
echo "ZIP:"
echo "$BASE_DIR/$ZIP_NAME"

echo ""
echo "LOG:"
echo "$LOG_FILE"