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
echo -e "${PURPLE}    DİNAMİK RESİM DÖNÜŞTÜRÜCÜ${NC}"
echo -e "${PURPLE}=====================================${NC}"
echo ""

# SORU 0: Kaynak klasör path'i
DEFAULT_PATH="/home/cenker/Desktop/images"
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
SUPPORTED_FORMATS=("jpg" "jpeg" "png" "webp" "bmp" "tiff" "tif" "gif")
SUPPORTED_INPUT_FORMATS=("*.jpg" "*.jpeg" "*.png" "*.webp" "*.bmp" "*.tiff" "*.tif" "*.gif" "*.JPG" "*.JPEG" "*.PNG" "*.WEBP" "*.BMP" "*.TIFF" "*.TIF" "*.GIF")

# Kaynak klasördeki resim dosyalarını say
echo -e "${CYAN}📂 Kaynak klasör kontrol ediliyor: $SRC_DIR${NC}"
total_files=0
for pattern in "${SUPPORTED_INPUT_FORMATS[@]}"; do
    count=$(find "$SRC_DIR" -type f -name "$pattern" 2>/dev/null | wc -l)
    total_files=$((total_files + count))
done

if [ $total_files -eq 0 ]; then
    echo -e "${RED}❌ Kaynak klasörde desteklenen resim dosyası bulunamadı!${NC}"
    echo -e "${YELLOW}Desteklenen formatlar: jpg, jpeg, png, webp, bmp, tiff, tif, gif${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Toplam $total_files adet resim dosyası bulundu${NC}"
echo ""

# SORU 1: Hedef format
echo -e "${BLUE}🎯 SORU 1: Hangi formata dönüştürmek istiyorsunuz?${NC}"
echo -e "${YELLOW}Desteklenen formatlar: ${SUPPORTED_FORMATS[*]}${NC}"
while true; do
    read -p "Hedef format (örn: jpg, png, webp): " TARGET_FORMAT
    TARGET_FORMAT=$(echo "$TARGET_FORMAT" | tr '[:upper:]' '[:lower:]')
    
    if [[ " ${SUPPORTED_FORMATS[*]} " =~ " ${TARGET_FORMAT} " ]]; then
        echo -e "${GREEN}✅ Seçilen format: $TARGET_FORMAT${NC}"
        break
    else
        echo -e "${RED}❌ Geçersiz format! Lütfen desteklenen formatlardan birini seçin.${NC}"
    fi
done
echo ""

# SORU 2: Kalite ayarı
echo -e "${BLUE}🎯 SORU 2: Kalite ayarı (1-100 arası)${NC}"
echo -e "${YELLOW}Önerilen değerler: 90 (yüksek), 80 (orta), 70 (düşük)${NC}"
while true; do
    read -p "Kalite değeri (1-100): " QUALITY
    
    if [[ "$QUALITY" =~ ^[0-9]+$ ]] && [ "$QUALITY" -ge 1 ] && [ "$QUALITY" -le 100 ]; then
        echo -e "${GREEN}✅ Seçilen kalite: %$QUALITY${NC}"
        break
    else
        echo -e "${RED}❌ Geçersiz değer! 1-100 arası bir sayı girin.${NC}"
    fi
done
echo ""

# SORU 3: En büyük kenar uzunluğu
echo -e "${BLUE}🎯 SORU 3: En büyük kenar uzunluğu (piksel)${NC}"
echo -e "${YELLOW}Örnekler: 1024, 1920, 2048, 4096${NC}"
echo -e "${CYAN}(0 girerseniz orijinal boyutlarda dönüştürülür)${NC}"
while true; do
    read -p "En büyük kenar (piksel, 0=orijinal): " MAX_SIZE
    
    if [[ "$MAX_SIZE" =~ ^[0-9]+$ ]] && [ "$MAX_SIZE" -ge 0 ]; then
        if [ "$MAX_SIZE" -eq 0 ]; then
            echo -e "${GREEN}✅ Orijinal boyutlarda dönüştürülecek${NC}"
            RESIZE_OPTION=""
        else
            echo -e "${GREEN}✅ En büyük kenar: ${MAX_SIZE}px${NC}"
            RESIZE_OPTION="-resize ${MAX_SIZE}x${MAX_SIZE}>"
        fi
        break
    else
        echo -e "${RED}❌ Geçersiz değer! 0 veya pozitif bir sayı girin.${NC}"
    fi
done
echo ""

# SORU 4: Grayscale (Gri tonlama)
echo -e "${BLUE}🎯 SORU 4: Resimleri siyah-beyaz (grayscale) yapmak istiyor musunuz?${NC}"
echo -e "${YELLOW}1) Hayır, renkli kalsın${NC}"
echo -e "${YELLOW}2) Evet, siyah-beyaz yap${NC}"
while true; do
    read -p "Seçiminiz (1 veya 2): " GRAYSCALE_OPTION
    
    if [ "$GRAYSCALE_OPTION" = "1" ]; then
        GRAYSCALE=false
        GRAYSCALE_CMD=""
        echo -e "${GREEN}✅ Resimlerin renkleri korunacak${NC}"
        break
    elif [ "$GRAYSCALE_OPTION" = "2" ]; then
        GRAYSCALE=true
        GRAYSCALE_CMD="-colorspace Gray"
        echo -e "${GREEN}✅ Resimlere siyah-beyaz efekti uygulanacak${NC}"
        break
    else
        echo -e "${RED}❌ Geçersiz seçim! Lütfen 1 veya 2 girin.${NC}"
    fi
done
echo ""

# SORU 5: Kaydetme yeri
echo -e "${BLUE}🎯 SORU 5: Dönüştürülen resimleri nereye kaydedelim?${NC}"
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
echo -e "${PURPLE}📋 İŞLEM ÖZETİ:${NC}"
echo -e "   📁 Kaynak klasör: $SRC_DIR"
if [ "$REPLACE_ORIGINAL" = true ]; then
    echo -e "   📁 Hedef: ${RED}Orijinal dosyaların yerine${NC}"
else
    echo -e "   📁 Hedef klasör: $DST_DIR"
fi
echo -e "   🎯 Hedef format: $TARGET_FORMAT"
echo -e "   ⭐ Kalite: %$QUALITY"
if [ -n "$RESIZE_OPTION" ]; then
    echo -e "   📏 En büyük kenar: ${MAX_SIZE}px"
else
    echo -e "   📏 Boyut: Orijinal boyutlarda"
fi
if [ "$GRAYSCALE" = true ]; then
    echo -e "   🎨 Renk: ${CYAN}Siyah-beyaz (Grayscale)${NC}"
else
    echo -e "   🎨 Renk: Renkli"
fi
echo -e "   📊 Toplam dosya: $total_files adet"
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
processed=0
for pattern in "${SUPPORTED_INPUT_FORMATS[@]}"; do
    find "$SRC_DIR" -type f -name "$pattern" 2>/dev/null | while read -r f; do
        # Göreceli yol
        relative_path="${f#$SRC_DIR/}"
        
        # Uzantıyı değiştir
        filename=$(basename "$f")
        name_without_ext="${filename%.*}"
        
        if [ "$REPLACE_ORIGINAL" = true ]; then
            # Orijinal yerine kaydet - aynı dizinde
            out_relative="${relative_path%/*}/${name_without_ext}.${TARGET_FORMAT}"
            if [ "${relative_path%/*}" = "$relative_path" ]; then
                out_relative="${name_without_ext}.${TARGET_FORMAT}"
            fi
            out="$DST_DIR/$out_relative"
            
            # Eğer kaynak dosya ile hedef dosya formatı aynıysa, temp dosya kullan
            if [ "$f" = "$out" ]; then
                temp_out="${out}.tmp"
            else
                temp_out="$out"
            fi
        else
            # Yeni klasöre kaydet
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
        echo -e "${YELLOW}   🔄 İşleniyor: $relative_path${NC}"
        
        # Convert komutu oluştur
        if [ "$TARGET_FORMAT" = "jpg" ] || [ "$TARGET_FORMAT" = "jpeg" ]; then
            # JPG için şeffaf arka planı beyaz yap
            convert "$f" -background white -flatten $GRAYSCALE_CMD $RESIZE_OPTION -quality $QUALITY "$temp_out"
        else
            # Diğer formatlar için normal dönüştürme
            convert "$f" $GRAYSCALE_CMD $RESIZE_OPTION -quality $QUALITY "$temp_out"
        fi
        
        # Eğer temp dosya kullanıldıysa, orijinali sil ve temp'i yeniden adlandır
        if [ "$REPLACE_ORIGINAL" = true ] && [ "$f" = "$out" ]; then
            rm "$f"
            mv "$temp_out" "$out"
        fi
        
        # Eğer orijinal yerine kaydediyorsak ve format değiştiyse, eski dosyayı sil
        if [ "$REPLACE_ORIGINAL" = true ] && [ "$f" != "$out" ] && [ -f "$f" ]; then
            rm "$f"
        fi
        
        processed=$((processed + 1))
    done
done

echo -e "${GREEN}✅ Dönüştürme tamamlandı!${NC}"
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

echo -e "${PURPLE}=====================================${NC}"
echo -e "${PURPLE}           SONUÇ RAPORU${NC}"
echo -e "${PURPLE}=====================================${NC}"
echo -e "${BLUE}📊 Boyut Karşılaştırması:${NC}"
echo -e "   📥 Önce: ${before_mb} MB"
echo -e "   📤 Sonra: ${after_mb} MB"
if [ $diff_size -ge 0 ]; then
    echo -e "   ${GREEN}💾 Kazanç: ${diff_mb} MB (%${percent_change} küçülme)${NC}"
else
    echo -e "   ${RED}📈 Artış: ${diff_mb#-} MB (%${percent_change#-} büyüme)${NC}"
fi
echo -e "${PURPLE}=====================================${NC}"
echo ""
read -p "Kapatmak için Enter'a basın..."
