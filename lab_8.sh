#!/bin/bash

# === ПЕРЕМЕННЫЕ ===
SRC_DIR="/var/www/portfolio/files_doc_source"
IN_DIR="/var/www/portfolio/files_doc_in"
OUT_DIR="/var/www/portfolio/files_pdf_out"
ARCH_DIR="/var/www/portfolio/arhiv/files_doc_out"
BASE_DIR="/var/www/portfoliot"
LOG_FILE="/var/www/portfolio/process_doc.log"

# === ОЧИСТКА ЛОГА ===
echo "==== DOC TO PDF CONVERSION LOG ====" > "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# === СОЗДАНИЕ КАТАЛОГОВ ===
echo "Creating directories..."

sudo mkdir -p "$SRC_DIR"
sudo mkdir -p "$IN_DIR"
sudo mkdir -p "$OUT_DIR"
sudo mkdir -p "$ARCH_DIR"

# === УСТАНОВКА ПРОГРАММ ===
echo "Installing required packages..."

sudo apt update

sudo apt install -y \
    libreoffice \
    unoconv \
    apache2 \
    tar \
    bzip2 \
    zip

# === ЗАПУСК APACHE ===
sudo systemctl start apache2
sudo systemctl enable apache2

# === ПРОВЕРКА НАЛИЧИЯ DOC/DOCX ===
echo "Checking source files..."

DOC_COUNT=$(find "$SRC_DIR" -type f \( -iname "*.doc" -o -iname "*.docx" \) | wc -l)

if [ "$DOC_COUNT" -eq 0 ]; then
    echo "No DOC/DOCX files found in $SRC_DIR"
    echo "Put files into $SRC_DIR" >> "$LOG_FILE"
    exit 1
fi

# === КОПИРОВАНИЕ ФАЙЛОВ ===
echo "Copying files..."

find "$SRC_DIR" -type f \( -iname "*.doc" -o -iname "*.docx" \) | while read file
do
    sudo cp "$file" "$IN_DIR/"
    
    echo "Copied: $(basename "$file")" >> "$LOG_FILE"
done

# === КОНВЕРТАЦИЯ DOC/DOCX -> PDF ===
echo "Converting documents to PDF..."

for doc in "$IN_DIR"/*; do

    [ -f "$doc" ] || continue

    filename=$(basename "$doc")

    echo "Processing: $filename" >> "$LOG_FILE"

    # Конвертация через LibreOffice
    libreoffice --headless \
        --convert-to pdf \
        --outdir "$OUT_DIR" \
        "$doc"

    echo "Converted: $filename" >> "$LOG_FILE"

done

# === АРХИВАЦИЯ ИСХОДНЫХ ФАЙЛОВ ===
echo "Creating archive..."

ARCHIVE_NAME="doc_archive_$(date +%Y%m%d_%H%M%S).tar.bz2"

sudo tar -cjf \
    "$ARCH_DIR/$ARCHIVE_NAME" \
    -C "$IN_DIR" .

echo "Archive created: $ARCHIVE_NAME" >> "$LOG_FILE"

# === СОЗДАНИЕ ZIP АРХИВА ===
ZIP_NAME="doc_files_$(date +%Y%m%d_%H%M%S).zip"

sudo zip -r \
    "$ARCH_DIR/$ZIP_NAME" \
    "$IN_DIR"

echo "ZIP archive created: $ZIP_NAME" >> "$LOG_FILE"

# ==========================================
# СОЗДАНИЕ HTML СТРАНИЦЫ
# ==========================================

cat > "$BASE_DIR/documents.html" << 'EOF'
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DOC -> PDF Reports</title>

    <style>

        body {
            background: #111827;
            color: white;
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 30px;
        }

        h1 {
            text-align: center;
            margin-bottom: 40px;
            color: #60a5fa;
        }

        .container {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
            gap: 25px;
        }

        .card {
            background: #1f2937;
            border-radius: 12px;
            padding: 20px;
            transition: 0.3s;
        }

        .card:hover {
            transform: translateY(-5px);
            background: #374151;
        }

        h3 {
            color: #93c5fd;
            word-break: break-all;
        }

        a {
            display: inline-block;
            margin-top: 10px;
            text-decoration: none;
            color: white;
            background: #2563eb;
            padding: 10px 15px;
            border-radius: 8px;
        }

        a:hover {
            background: #1d4ed8;
        }

        .pdf-btn {
            background: #dc2626;
        }

        .pdf-btn:hover {
            background: #b91c1c;
        }

    </style>
</head>

<body>

<h1>Документы DOC/DOCX и PDF</h1>

<div class="container">
EOF

# === ДОБАВЛЕНИЕ DOC/DOCX ===
for doc in "$IN_DIR"/*; do

    [ -f "$doc" ] || continue

    filename=$(basename "$doc")

    filesize=$(stat -c%s "$doc")
    size_kb=$(awk "BEGIN {printf \"%.2f\", $filesize/1024}")

    pdf_name="${filename%.*}.pdf"

cat >> "$BASE_DIR/documents.html" << EOF

<div class="card">

    <h3>$filename</h3>

    <p>Size: ${size_kb} KB</p>

    <a href="files_doc_in/$filename" download>
        Download DOC
    </a>

    <br>

    <a class="pdf-btn"
       href="files_pdf_out/$pdf_name"
       target="_blank">
       Open PDF
    </a>

</div>

EOF

done

# === ЗАКРЫТИЕ HTML ===
cat >> "$BASE_DIR/documents.html" << 'EOF'

</div>

</body>
</html>

EOF

# === ПРАВА ДОСТУПА ===
sudo chown -R www-data:www-data "$BASE_DIR"

sudo chmod -R 755 "$BASE_DIR"

# === ЗАВЕРШЕНИЕ ===
echo ""
echo "=================================="
echo "DONE!"
echo "=================================="

echo "Website:"
echo "http://$(hostname -I | awk '{print $1}')/documents.html"

echo ""
echo "PDF files:"
echo "$OUT_DIR"

echo ""
echo "Archives:"
echo "$ARCH_DIR"

echo ""
echo "Log file:"
echo "$LOG_FILE"