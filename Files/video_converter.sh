#!/bin/bash

# Renkli çıktı için ANSI kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Başlık
echo -e "${PURPLE}=====================================${NC}"
echo -e "${PURPLE}    DİNAMİK VİDEO DÖNÜŞTÜRÜCÜ${NC}"
echo -e "${PURPLE}=====================================${NC}"
echo ""

# FFmpeg kontrolü
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${RED}❌ HATA: FFmpeg bulunamadı!${NC}"
    echo -e "${YELLOW}Lütfen FFmpeg'i yükleyin: sudo apt install ffmpeg${NC}"
    exit 1
fi

# SORU 0: Kaynak klasör path'i
DEFAULT_PATH="/home/cenker/Desktop/videos"
echo -e "${BLUE}🎯 SORU 0: Kaynak klasör yolu${NC}"
echo -e "${YELLOW}Varsayılan: $DEFAULT_PATH${NC}"
echo -e "${CYAN}(Boş bırakırsanız varsayılan kullanılır)${NC}"

while true; do
    read -p "Kaynak klasör yolu: " SRC_DIR
    
    # Boş bırakılırsa varsayılanı kullan
    if [ -z "$SRC_DIR" ]; then
        SRC_DIR="$DEFAULT_PATH"
        echo -e "${CYAN}ℹ️  Varsayılan klasör kullanılıyor: $SRC_DIR${NC}"
    fi
    
    # Kaynak klasörün var olup olmadığını kontrol et
    if [ ! -d "$SRC_DIR" ]; then
        echo -e "${RED}❌ Hata: '$SRC_DIR' klasörü bulunamadı!${NC}"
        echo -e "${YELLOW}Lütfen geçerli bir klasör yolu girin veya klasörü oluşturun.${NC}"
        echo ""
    else
        echo -e "${GREEN}✅ Klasör bulundu: $SRC_DIR${NC}"
        break
    fi
done
echo ""

# Desteklenen format listesi
SUPPORTED_INPUT_FORMATS=("*.mp4" "*.avi" "*.mkv" "*.mov" "*.webm" "*.flv" "*.wmv" "*.m4v" "*.mpeg" "*.mpg" "*.MP4" "*.AVI" "*.MKV" "*.MOV" "*.WEBM" "*.FLV" "*.WMV" "*.M4V" "*.MPEG" "*.MPG")

# Kaynak klasördeki video dosyalarını say
echo -e "${CYAN}📂 Kaynak klasör kontrol ediliyor: $SRC_DIR${NC}"
total_files=0
for pattern in "${SUPPORTED_INPUT_FORMATS[@]}"; do
    count=$(find "$SRC_DIR" -type f -name "$pattern" 2>/dev/null | wc -l)
    total_files=$((total_files + count))
done

if [ $total_files -eq 0 ]; then
    echo -e "${RED}❌ Kaynak klasörde desteklenen video dosyası bulunamadı!${NC}"
    echo -e "${YELLOW}Desteklenen formatlar: mp4, avi, mkv, mov, webm, flv, wmv, m4v, mpeg, mpg${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Toplam $total_files adet video dosyası bulundu${NC}"
echo ""

# SORU 1: Hedef format
echo -e "${BLUE}🎯 SORU 1: Hangi formata dönüştürmek istiyorsunuz?${NC}"
echo -e "${YELLOW}Popüler formatlar:${NC}"
echo -e "   ${CYAN}mp4${NC}  - En yaygın, çoğu cihazla uyumlu"
echo -e "   ${CYAN}webm${NC} - Web için optimize, küçük boyut"
echo -e "   ${CYAN}mkv${NC}  - Yüksek kalite, çoklu ses/altyazı"
echo -e "   ${CYAN}avi${NC}  - Eski uyumluluk"
echo -e "   ${CYAN}mov${NC}  - Apple cihazlar için"
echo -e "${YELLOW}Diğer: flv, wmv, m4v, mpeg${NC}"

while true; do
    read -p "Hedef format: " TARGET_FORMAT
    TARGET_FORMAT=$(echo "$TARGET_FORMAT" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$TARGET_FORMAT" =~ ^(mp4|webm|mkv|avi|mov|flv|wmv|m4v|mpeg)$ ]]; then
        echo -e "${GREEN}✅ Seçilen format: $TARGET_FORMAT${NC}"
        break
    else
        echo -e "${RED}❌ Geçersiz format! Lütfen desteklenen formatlardan birini seçin.${NC}"
    fi
done
echo ""

# SORU 2: Video Codec
echo -e "${BLUE}🎯 SORU 2: Video codec seçimi${NC}"
echo -e "${YELLOW}Codec seçenekleri (formata göre):${NC}"

# Format bazlı codec önerileri
case $TARGET_FORMAT in
    mp4)
        echo -e "   ${CYAN}1)${NC} libx264 - H.264 (En uyumlu, orta boyut)"
        echo -e "   ${CYAN}2)${NC} libx265 - H.265/HEVC (Daha küçük boyut, yeni cihazlar)"
        echo -e "   ${CYAN}3)${NC} copy - Yeniden kodlama yapma (hızlı, kaynak codec)"
        CODEC_OPTIONS=("libx264" "libx265" "copy")
        ;;
    webm)
        echo -e "   ${CYAN}1)${NC} libvpx - VP8 (Eski uyumluluk)"
        echo -e "   ${CYAN}2)${NC} libvpx-vp9 - VP9 (Daha iyi kalite/boyut)"
        echo -e "   ${CYAN}3)${NC} copy - Yeniden kodlama yapma (hızlı, kaynak codec)"
        CODEC_OPTIONS=("libvpx" "libvpx-vp9" "copy")
        ;;
    mkv)
        echo -e "   ${CYAN}1)${NC} libx264 - H.264 (Uyumlu)"
        echo -e "   ${CYAN}2)${NC} libx265 - H.265/HEVC (Küçük boyut)"
        echo -e "   ${CYAN}3)${NC} libvpx-vp9 - VP9 (Açık kaynak)"
        echo -e "   ${CYAN}4)${NC} copy - Yeniden kodlama yapma (hızlı, kaynak codec)"
        CODEC_OPTIONS=("libx264" "libx265" "libvpx-vp9" "copy")
        ;;
    *)
        echo -e "   ${CYAN}1)${NC} libx264 - H.264 (Genel amaçlı)"
        echo -e "   ${CYAN}2)${NC} copy - Yeniden kodlama yapma (hızlı)"
        CODEC_OPTIONS=("libx264" "copy")
        ;;
esac

while true; do
    read -p "Codec seçimi (numara): " CODEC_CHOICE
    
    if [[ "$CODEC_CHOICE" =~ ^[0-9]+$ ]] && [ "$CODEC_CHOICE" -ge 1 ] && [ "$CODEC_CHOICE" -le ${#CODEC_OPTIONS[@]} ]; then
        VIDEO_CODEC="${CODEC_OPTIONS[$((CODEC_CHOICE-1))]}"
        echo -e "${GREEN}✅ Seçilen codec: $VIDEO_CODEC${NC}"
        break
    else
        echo -e "${RED}❌ Geçersiz seçim! 1-${#CODEC_OPTIONS[@]} arası bir numara girin.${NC}"
    fi
done
echo ""

# SORU 3: Bitrate (sadece copy değilse)
if [ "$VIDEO_CODEC" != "copy" ]; then
    echo -e "${BLUE}🎯 SORU 3: Video bitrate${NC}"
    echo -e "${YELLOW}Kalite seviyeleri:${NC}"
    echo -e "   ${CYAN}1)${NC} Düşük kalite  - 1000k (1 Mbps) - Küçük boyut"
    echo -e "   ${CYAN}2)${NC} Orta kalite   - 2500k (2.5 Mbps) - Dengeli"
    echo -e "   ${CYAN}3)${NC} İyi kalite    - 5000k (5 Mbps) - İyi görüntü"
    echo -e "   ${CYAN}4)${NC} Yüksek kalite - 8000k (8 Mbps) - Çok iyi"
    echo -e "   ${CYAN}5)${NC} Özel değer gir"
    
    while true; do
        read -p "Bitrate seçimi: " BITRATE_CHOICE
        
        case $BITRATE_CHOICE in
            1)
                VIDEO_BITRATE="1000k"
                echo -e "${GREEN}✅ Bitrate: 1000k (Düşük kalite)${NC}"
                break
                ;;
            2)
                VIDEO_BITRATE="2500k"
                echo -e "${GREEN}✅ Bitrate: 2500k (Orta kalite)${NC}"
                break
                ;;
            3)
                VIDEO_BITRATE="5000k"
                echo -e "${GREEN}✅ Bitrate: 5000k (İyi kalite)${NC}"
                break
                ;;
            4)
                VIDEO_BITRATE="8000k"
                echo -e "${GREEN}✅ Bitrate: 8000k (Yüksek kalite)${NC}"
                break
                ;;
            5)
                while true; do
                    read -p "Özel bitrate değeri (örn: 3000k, 10M): " CUSTOM_BITRATE
                    if [[ "$CUSTOM_BITRATE" =~ ^[0-9]+[kKmM]$ ]]; then
                        VIDEO_BITRATE="$CUSTOM_BITRATE"
                        echo -e "${GREEN}✅ Bitrate: $VIDEO_BITRATE${NC}"
                        break 2
                    else
                        echo -e "${RED}❌ Geçersiz format! Örnek: 3000k veya 10M${NC}"
                    fi
                done
                ;;
            *)
                echo -e "${RED}❌ Geçersiz seçim! 1-5 arası bir numara girin.${NC}"
                ;;
        esac
    done
else
    VIDEO_BITRATE="copy"
    echo -e "${YELLOW}ℹ️  Codec 'copy' modunda - bitrate ayarı gerekmiyor${NC}"
fi
echo ""

# SORU 4: Çözünürlük (Resolution/Scale)
if [ "$VIDEO_CODEC" != "copy" ]; then
    echo -e "${BLUE}🎯 SORU 4: Video çözünürlüğü (scale)${NC}"
    echo -e "${YELLOW}Çözünürlük seçenekleri:${NC}"
    echo -e "   ${CYAN}1)${NC} Orijinal boyut (değişiklik yok)"
    echo -e "   ${CYAN}2)${NC} 4K (3840x2160)"
    echo -e "   ${CYAN}3)${NC} 1080p (1920x1080) - Full HD"
    echo -e "   ${CYAN}4)${NC} 720p (1280x720) - HD"
    echo -e "   ${CYAN}5)${NC} 480p (854x480) - SD"
    echo -e "   ${CYAN}6)${NC} En büyük kenar limiti (oran korunur)"
    
    while true; do
        read -p "Çözünürlük seçimi: " SCALE_CHOICE
        
        case $SCALE_CHOICE in
            1)
                SCALE_OPTION=""
                echo -e "${GREEN}✅ Orijinal çözünürlük korunacak${NC}"
                break
                ;;
            2)
                SCALE_OPTION="-vf scale=3840:2160:force_original_aspect_ratio=decrease"
                echo -e "${GREEN}✅ 4K (3840x2160)${NC}"
                break
                ;;
            3)
                SCALE_OPTION="-vf scale=1920:1080:force_original_aspect_ratio=decrease"
                echo -e "${GREEN}✅ 1080p (1920x1080)${NC}"
                break
                ;;
            4)
                SCALE_OPTION="-vf scale=1280:720:force_original_aspect_ratio=decrease"
                echo -e "${GREEN}✅ 720p (1280x720)${NC}"
                break
                ;;
            5)
                SCALE_OPTION="-vf scale=854:480:force_original_aspect_ratio=decrease"
                echo -e "${GREEN}✅ 480p (854x480)${NC}"
                break
                ;;
            6)
                while true; do
                    read -p "En büyük kenar uzunluğu (piksel, örn: 1920): " MAX_DIMENSION
                    if [[ "$MAX_DIMENSION" =~ ^[0-9]+$ ]] && [ "$MAX_DIMENSION" -gt 0 ]; then
                        SCALE_OPTION="-vf scale='min($MAX_DIMENSION,iw)':'min($MAX_DIMENSION,ih)':force_original_aspect_ratio=decrease"
                        echo -e "${GREEN}✅ En büyük kenar: ${MAX_DIMENSION}px (oran korunur)${NC}"
                        break 2
                    else
                        echo -e "${RED}❌ Geçersiz değer! Pozitif bir sayı girin.${NC}"
                    fi
                done
                ;;
            *)
                echo -e "${RED}❌ Geçersiz seçim! 1-6 arası bir numara girin.${NC}"
                ;;
        esac
    done
else
    SCALE_OPTION=""
    echo -e "${YELLOW}ℹ️  Codec 'copy' modunda - çözünürlük değiştirilemez${NC}"
fi
echo ""

# SORU 5: Ses codec ve kalite
echo -e "${BLUE}🎯 SORU 5: Ses (Audio) ayarları${NC}"
echo -e "${YELLOW}Ses codec seçenekleri:${NC}"
echo -e "   ${CYAN}1)${NC} AAC - Çok uyumlu (mp4, mkv için önerilen)"
echo -e "   ${CYAN}2)${NC} Opus - Yüksek kalite/düşük boyut (webm, mkv)"
echo -e "   ${CYAN}3)${NC} MP3 - Eski uyumluluk"
echo -e "   ${CYAN}4)${NC} Copy - Ses değişmez (hızlı)"
echo -e "   ${CYAN}5)${NC} Sessiz - Ses kanalını kaldır"

while true; do
    read -p "Ses codec seçimi: " AUDIO_CHOICE
    
    case $AUDIO_CHOICE in
        1)
            AUDIO_CODEC="aac"
            read -p "Ses bitrate (örn: 128k, 192k, 256k) [varsayılan: 192k]: " AUDIO_BITRATE
            AUDIO_BITRATE=${AUDIO_BITRATE:-192k}
            AUDIO_OPTIONS="-c:a aac -b:a $AUDIO_BITRATE"
            echo -e "${GREEN}✅ Ses: AAC @ $AUDIO_BITRATE${NC}"
            break
            ;;
        2)
            AUDIO_CODEC="libopus"
            read -p "Ses bitrate (örn: 96k, 128k, 192k) [varsayılan: 128k]: " AUDIO_BITRATE
            AUDIO_BITRATE=${AUDIO_BITRATE:-128k}
            AUDIO_OPTIONS="-c:a libopus -b:a $AUDIO_BITRATE"
            echo -e "${GREEN}✅ Ses: Opus @ $AUDIO_BITRATE${NC}"
            break
            ;;
        3)
            AUDIO_CODEC="libmp3lame"
            read -p "Ses bitrate (örn: 128k, 192k, 256k) [varsayılan: 192k]: " AUDIO_BITRATE
            AUDIO_BITRATE=${AUDIO_BITRATE:-192k}
            AUDIO_OPTIONS="-c:a libmp3lame -b:a $AUDIO_BITRATE"
            echo -e "${GREEN}✅ Ses: MP3 @ $AUDIO_BITRATE${NC}"
            break
            ;;
        4)
            AUDIO_CODEC="copy"
            AUDIO_OPTIONS="-c:a copy"
            echo -e "${GREEN}✅ Ses: Orijinal ses korunacak${NC}"
            break
            ;;
        5)
            AUDIO_CODEC="none"
            AUDIO_OPTIONS="-an"
            echo -e "${GREEN}✅ Ses: Video sessiz olacak${NC}"
            break
            ;;
        *)
            echo -e "${RED}❌ Geçersiz seçim! 1-5 arası bir numara girin.${NC}"
            ;;
    esac
done
echo ""

# SORU 6: FPS (Frame Rate)
if [ "$VIDEO_CODEC" != "copy" ]; then
    echo -e "${BLUE}🎯 SORU 6: Frame rate (FPS) ayarı${NC}"
    echo -e "${YELLOW}FPS seçenekleri:${NC}"
    echo -e "   ${CYAN}1)${NC} Orijinal FPS'i koru"
    echo -e "   ${CYAN}2)${NC} 24 fps (Sinema)"
    echo -e "   ${CYAN}3)${NC} 30 fps (Standart)"
    echo -e "   ${CYAN}4)${NC} 60 fps (Akıcı)"
    echo -e "   ${CYAN}5)${NC} Özel değer"
    
    while true; do
        read -p "FPS seçimi: " FPS_CHOICE
        
        case $FPS_CHOICE in
            1)
                FPS_OPTION=""
                echo -e "${GREEN}✅ Orijinal FPS korunacak${NC}"
                break
                ;;
            2)
                FPS_OPTION="-r 24"
                echo -e "${GREEN}✅ FPS: 24${NC}"
                break
                ;;
            3)
                FPS_OPTION="-r 30"
                echo -e "${GREEN}✅ FPS: 30${NC}"
                break
                ;;
            4)
                FPS_OPTION="-r 60"
                echo -e "${GREEN}✅ FPS: 60${NC}"
                break
                ;;
            5)
                while true; do
                    read -p "Özel FPS değeri (örn: 25, 50): " CUSTOM_FPS
                    if [[ "$CUSTOM_FPS" =~ ^[0-9]+$ ]] && [ "$CUSTOM_FPS" -gt 0 ]; then
                        FPS_OPTION="-r $CUSTOM_FPS"
                        echo -e "${GREEN}✅ FPS: $CUSTOM_FPS${NC}"
                        break 2
                    else
                        echo -e "${RED}❌ Geçersiz değer! Pozitif bir sayı girin.${NC}"
                    fi
                done
                ;;
            *)
                echo -e "${RED}❌ Geçersiz seçim! 1-5 arası bir numara girin.${NC}"
                ;;
        esac
    done
else
    FPS_OPTION=""
    echo -e "${YELLOW}ℹ️  Codec 'copy' modunda - FPS değiştirilemez${NC}"
fi
echo ""

# SORU 7: Kaydetme yeri
echo -e "${BLUE}🎯 SORU 7: Dönüştürülen videoları nereye kaydedelim?${NC}"
echo -e "${YELLOW}1) Yeni bir klasöre (${SRC_DIR}_${TARGET_FORMAT}_version)${NC}"
echo -e "${YELLOW}2) Orijinal dosyaların yerine${NC}"

while true; do
    read -p "Seçiminiz (1 veya 2): " SAVE_OPTION
    
    if [ "$SAVE_OPTION" = "1" ]; then
        DST_DIR="${SRC_DIR}_${TARGET_FORMAT}_version"
        REPLACE_ORIGINAL=false
        echo -e "${GREEN}✅ Yeni klasöre kaydedilecek: $DST_DIR${NC}"
        mkdir -p "$DST_DIR"
        break
    elif [ "$SAVE_OPTION" = "2" ]; then
        DST_DIR="$SRC_DIR"
        REPLACE_ORIGINAL=true
        echo -e "${YELLOW}⚠️  Orijinal dosyaların yerine kaydedilecek!${NC}"
        echo -e "${RED}⚠️  DİKKAT: Bu işlem geri alınamaz!${NC}"
        read -p "Devam etmek istediğinizden emin misiniz? (evet/hayır): " confirm
        if [ "$confirm" = "evet" ]; then
            echo -e "${GREEN}✅ Orijinal dosyaların yerine kaydedilecek${NC}"
            break
        else
            echo -e "${YELLOW}İşlem iptal edildi, lütfen tekrar seçim yapın.${NC}"
        fi
    else
        echo -e "${RED}❌ Geçersiz seçim! Lütfen 1 veya 2 girin.${NC}"
    fi
done
echo ""

# Özet göster
echo -e "${PURPLE}=====================================${NC}"
echo -e "${PURPLE}           İŞLEM ÖZETİ${NC}"
echo -e "${PURPLE}=====================================${NC}"
echo -e "   📁 Kaynak klasör: $SRC_DIR"
if [ "$REPLACE_ORIGINAL" = true ]; then
    echo -e "   📁 Hedef: ${RED}Orijinal dosyaların yerine${NC}"
else
    echo -e "   📁 Hedef klasör: $DST_DIR"
fi
echo -e "   🎯 Hedef format: $TARGET_FORMAT"
echo -e "   🎬 Video codec: $VIDEO_CODEC"
if [ "$VIDEO_CODEC" != "copy" ]; then
    echo -e "   📊 Video bitrate: $VIDEO_BITRATE"
fi
if [ -n "$SCALE_OPTION" ]; then
    echo -e "   📐 Çözünürlük: Ölçeklendirilecek"
else
    echo -e "   📐 Çözünürlük: Orijinal"
fi
echo -e "   🔊 Ses codec: $AUDIO_CODEC"
if [ -n "$FPS_OPTION" ]; then
    echo -e "   🎞️  FPS: Değiştirilecek"
else
    echo -e "   🎞️  FPS: Orijinal"
fi
echo -e "   📊 Toplam dosya: $total_files adet"
echo -e "${PURPLE}=====================================${NC}"
echo ""

# Onay al
read -p "İşleme başlamak için Enter'a basın (Ctrl+C ile iptal): "
echo ""

# Boyut hesaplama (işlem öncesi)
echo -e "${CYAN}📏 Kaynak dosyaların toplam boyutu hesaplanıyor...${NC}"
before_size=0
for pattern in "${SUPPORTED_INPUT_FORMATS[@]}"; do
    while IFS= read -r -d '' file; do
        if [ -f "$file" ]; then
            size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
            before_size=$((before_size + size))
        fi
    done < <(find "$SRC_DIR" -type f -name "$pattern" -print0 2>/dev/null)
done

# Dönüştürme işlemi
echo -e "${GREEN}🔄 Dönüştürme işlemi başlıyor...${NC}"
echo ""
processed=0
failed=0

for pattern in "${SUPPORTED_INPUT_FORMATS[@]}"; do
    find "$SRC_DIR" -type f -name "$pattern" 2>/dev/null | while read -r f; do
        # Göreceli yol
        relative_path="${f#$SRC_DIR/}"
        
        # Uzantıyı değiştir
        filename=$(basename "$f")
        name_without_ext="${filename%.*}"
        
        if [ "$REPLACE_ORIGINAL" = true ]; then
            out_relative="${relative_path%/*}/${name_without_ext}.${TARGET_FORMAT}"
            if [ "${relative_path%/*}" = "$relative_path" ]; then
                out_relative="${name_without_ext}.${TARGET_FORMAT}"
            fi
            out="$DST_DIR/$out_relative"
            temp_out="${out}.tmp.${TARGET_FORMAT}"
        else
            out_relative="${relative_path%/*}/${name_without_ext}.${TARGET_FORMAT}"
            if [ "${relative_path%/*}" = "$relative_path" ]; then
                out_relative="${name_without_ext}.${TARGET_FORMAT}"
            fi
            out="$DST_DIR/$out_relative"
            temp_out="$out"
        fi
        
        # Çıktı klasörünü oluştur
        mkdir -p "$(dirname "$temp_out")"
        
        # İşlemi göster
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}🎬 İşleniyor: $relative_path${NC}"
        
        # FFmpeg komutu oluştur
        FFMPEG_CMD="ffmpeg -i \"$f\" -y"
        
        # Video codec
        if [ "$VIDEO_CODEC" = "copy" ]; then
            FFMPEG_CMD="$FFMPEG_CMD -c:v copy"
        else
            FFMPEG_CMD="$FFMPEG_CMD -c:v $VIDEO_CODEC -b:v $VIDEO_BITRATE"
        fi
        
        # Ses ayarları
        FFMPEG_CMD="$FFMPEG_CMD $AUDIO_OPTIONS"
        
        # Scale
        if [ -n "$SCALE_OPTION" ]; then
            FFMPEG_CMD="$FFMPEG_CMD $SCALE_OPTION"
        fi
        
        # FPS
        if [ -n "$FPS_OPTION" ]; then
            FFMPEG_CMD="$FFMPEG_CMD $FPS_OPTION"
        fi
        
        # Çıktı dosyası
        FFMPEG_CMD="$FFMPEG_CMD \"$temp_out\""
        
        # Komutu çalıştır
        eval $FFMPEG_CMD 2>&1 | grep -E "frame=|time=|speed=|error|Error|failed|Failed" || true
        
        # Başarı kontrolü
        if [ $? -eq 0 ] && [ -f "$temp_out" ]; then
            # Eğer orijinal yerine kaydediyorsak
            if [ "$REPLACE_ORIGINAL" = true ]; then
                rm "$f"
                mv "$temp_out" "$out"
            fi
            
            echo -e "${GREEN}✅ Tamamlandı: $relative_path${NC}"
            processed=$((processed + 1))
        else
            echo -e "${RED}❌ HATA: $relative_path dönüştürülemedi!${NC}"
            failed=$((failed + 1))
            # Başarısız temp dosyayı temizle
            [ -f "$temp_out" ] && rm "$temp_out"
        fi
        echo ""
    done
done

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Dönüştürme işlemi tamamlandı!${NC}"
echo -e "${BLUE}📊 Başarılı: $processed adet${NC}"
if [ $failed -gt 0 ]; then
    echo -e "${RED}❌ Başarısız: $failed adet${NC}"
fi
echo ""

# Sonuç boyutu hesapla
echo -e "${CYAN}📏 Sonuç dosyaların toplam boyutu hesaplanıyor...${NC}"
after_size=0
target_pattern="*.${TARGET_FORMAT}"
target_pattern_upper="*.$(echo $TARGET_FORMAT | tr '[:lower:]' '[:upper:]')"

for pattern in "$target_pattern" "$target_pattern_upper"; do
    while IFS= read -r -d '' file; do
        if [ -f "$file" ]; then
            size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
            after_size=$((after_size + size))
        fi
    done < <(find "$DST_DIR" -type f -name "$pattern" -print0 2>/dev/null)
done

# Sonuç raporu
diff_size=$((before_size - after_size))
before_mb=$(awk -v b="$before_size" 'BEGIN {printf "%.2f", b / 1024 / 1024}')
after_mb=$(awk -v a="$after_size" 'BEGIN {printf "%.2f", a / 1024 / 1024}')
diff_mb=$(awk -v d="$diff_size" 'BEGIN {printf "%.2f", d / 1024 / 1024}')

if [ $before_size -gt 0 ]; then
    percent_change=$(awk -v diff="$diff_size" -v before="$before_size" 'BEGIN {printf "%.2f", (diff / before) * 100}')
else
    percent_change="0.00"
fi

echo ""
echo -e "${PURPLE}=====================================${NC}"
echo -e "${PURPLE}           SONUÇ RAPORU${NC}"
echo -e "${PURPLE}=====================================${NC}"
echo -e "${BLUE}📊 Boyut Karşılaştırması:${NC}"
echo -e "   📥 Önce: ${before_mb} MB"
echo -e "   📤 Sonra: ${after_mb} MB"
if [ $diff_size -ge 0 ]; then
    echo -e "   ${GREEN}💾 Kazanç: ${diff_mb} MB (%${percent_change} küçülme)${NC}"
else
    diff_mb_positive=${diff_mb#-}
    percent_change_positive=${percent_change#-}
    echo -e "   ${RED}📈 Artış: ${diff_mb_positive} MB (%${percent_change_positive} büyüme)${NC}"
fi
echo -e "${BLUE}📈 İşlem İstatistikleri:${NC}"
echo -e "   ✅ Başarılı: $processed/$total_files"
if [ $failed -gt 0 ]; then
    echo -e "   ❌ Başarısız: $failed/$total_files"
fi
echo -e "${PURPLE}=====================================${NC}"
echo ""
echo -e "${GREEN}🎉 Tüm işlemler tamamlandı!${NC}"
if [ "$REPLACE_ORIGINAL" = false ]; then
    echo -e "${CYAN}📁 Dönüştürülen dosyalar: $DST_DIR${NC}"
fi
echo ""
read -p "Kapatmak için Enter'a basın..."
