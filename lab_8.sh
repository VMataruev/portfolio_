#!/bin/bash

# === ПЕРЕМЕННЫЕ ===
SRC_DIR="/var/www/portfolio/files_doc_source"
IN_DIR="/var/www/portfolio/files_doc_in"
OUT_DIR="/var/www/portfolio/files_pdf_out"
ARCH_DIR="/var/www/portfolio/arhiv/files_doc_out"
BASE_DIR="/var/www/portfolio"
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
# СОЗДАНИЕ HTML СТРАНИЦЫ (с просмотром PDF)
# ==========================================

cat > "$BASE_DIR/word_original.html" << 'EOF'
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Портфолио - Документы DOC и PDF</title>
    <link rel="stylesheet" href="styles.css">
    <link rel="stylesheet" href="main.css">
    <style>
        .doc-section {
            margin: 120px 40px 40px 40px;
        }
        .doc-title {
            color: var(--brand-main);
            font-size: 28px;
            margin-bottom: 30px;
            padding-left: 20px;
            border-left: 4px solid var(--brand-main);
        }
        .doc-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(450px, 1fr));
            gap: 30px;
            margin-bottom: 60px;
        }
        .doc-card {
            background: rgba(255,255,255,0.05);
            border-radius: 15px;
            padding: 20px;
            transition: transform 0.3s ease;
        }
        .doc-card:hover {
            transform: translateY(-5px);
            background: rgba(255,255,255,0.1);
        }
        .pdf-viewer {
            width: 100%;
            height: 400px;
            border: none;
            border-radius: 10px;
            margin-bottom: 15px;
            background: #1f2937;
        }
        .doc-card h3 {
            color: var(--brand-main);
            margin-bottom: 10px;
            font-size: 14px;
            word-break: break-all;
        }
        .doc-card p {
            color: var(--text-gray);
            font-size: 14px;
            margin: 5px 0;
        }
        .button-group {
            display: flex;
            gap: 10px;
            margin-top: 15px;
            flex-wrap: wrap;
        }
        .btn {
            display: inline-block;
            padding: 8px 16px;
            border-radius: 8px;
            text-decoration: none;
            font-size: 14px;
            transition: all 0.3s ease;
            cursor: pointer;
            border: none;
            font-family: inherit;
        }
        .btn-download {
            background: #2563eb;
            color: white;
        }
        .btn-download:hover {
            background: #1d4ed8;
            transform: translateY(-2px);
        }
        .btn-pdf {
            background: #dc2626;
            color: white;
        }
        .btn-pdf:hover {
            background: #b91c1c;
            transform: translateY(-2px);
        }
        .btn-fullscreen {
            background: #10b981;
            color: white;
        }
        .btn-fullscreen:hover {
            background: #059669;
            transform: translateY(-2px);
        }
        .badge-doc {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 12px;
            background: rgba(37,99,235,0.3);
            color: #60a5fa;
            margin-top: 10px;
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
            <a href="./video_original.html">Видео</a>
            <div class="a_box_line"></div>
        </div>
        <div class="a_box">
            <a href="./word_original.html">Документы</a>
            <div class="a_box_line"></div>
        </div>
    </header>

    <div class="doc-section">
        <div class="doc-title">Документы DOC/DOCX и PDF</div>
        <div class="doc-grid" id="docGrid">
EOF

# === ДОБАВЛЕНИЕ КАРТОЧЕК ДОКУМЕНТОВ ===
for doc in "$IN_DIR"/*; do
    [ -f "$doc" ] || continue
    
    filename=$(basename "$doc")
    filesize=$(stat -c%s "$doc")
    size_kb=$(awk "BEGIN {printf \"%.2f\", $filesize/1024}")
    pdf_name="${filename%.*}.pdf"
    
    # Генерируем уникальный ID для PDF элемента
    pdf_id=$(echo "$filename" | sha256sum | cut -c1-8)
    
    cat >> "$BASE_DIR/word_original.html" << EOF
            <div class="doc-card" data-doc="$filename">
                <iframe class="pdf-viewer" id="pdf-$pdf_id" src="files_pdf_out/$pdf_name" frameborder="0"></iframe>
                <h3>$filename</h3>
                <p>📄 Размер: ${size_kb} KB</p>
                <div class="badge-doc">📝 DOC/DOCX → PDF</div>
                <div class="button-group">
                    <a href="files_doc_in/$filename" download class="btn btn-download">📥 Скачать DOC</a>
                    <a href="files_pdf_out/$pdf_name" target="_blank" class="btn btn-pdf">📖 Открыть PDF</a>
                    <button class="btn btn-fullscreen" onclick="fullscreenPdf('pdf-$pdf_id')">🖥️ Во весь экран</button>
                </div>
            </div>
EOF
done

cat >> "$BASE_DIR/word_original.html" << 'EOF'
        </div>
    </div>

    <script src="main.js"></script>
    <script src="stars.js"></script>
    <script>
        // Функция для полноэкранного режима PDF
        function fullscreenPdf(elementId) {
            const iframe = document.getElementById(elementId);
            if (iframe.requestFullscreen) {
                iframe.requestFullscreen();
            } else if (iframe.webkitRequestFullscreen) {
                iframe.webkitRequestFullscreen();
            } else if (iframe.msRequestFullscreen) {
                iframe.msRequestFullscreen();
            }
        }
        
        // Добавляем стили для полноэкранного режима
        const style = document.createElement('style');
        style.textContent = `
            :-webkit-full-screen {
                width: 100%;
                height: 100%;
            }
            :fullscreen {
                width: 100%;
                height: 100%;
            }
        `;
        document.head.appendChild(style);
        
        console.log('PDF просмотрщик загружен. Документов: ' + document.querySelectorAll('.doc-card').length);
    </script>
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
echo "http://$(hostname -I | awk '{print $1}')/word_original.html"

echo ""
echo "PDF files:"
echo "$OUT_DIR"

echo ""
echo "Archives:"
echo "$ARCH_DIR"

echo ""
echo "Log file:"
echo "$LOG_FILE"