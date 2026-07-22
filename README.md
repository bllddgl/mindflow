# MindFlow

TXT, PDF, DOCX, Markdown ve HTML belgelerini içe aktarıp RSVP (hızlı okuma)
tekniğiyle okumanızı sağlayan bir Flutter uygulaması. Mimari; Clean
Architecture + feature-first klasörleme + Riverpod + GoRouter + Material 3
üzerine kurulu ve Windows/iOS/Web/tarayıcı eklentisi gibi gelecekteki
hedefleri büyük bir yeniden yazım olmadan destekleyecek şekilde tasarlandı.

---

## 🇹🇷 Bu kodu gerçek bir Android kurulum dosyasına (APK) nasıl çeviririm?

Bilgisayarınıza hiçbir program kurmadan, tamamen tarayıcı üzerinden,
**ücretsiz** olarak yapabilirsiniz. İki hesap açmanız yeterli: GitHub ve
Codemagic. İkisi de kredi kartı istemiyor.

### 1. Adım — GitHub'a kod deposu (repository) oluşturun

1. [github.com](https://github.com) adresine gidin, hesabınız yoksa "Sign up"
   ile ücretsiz bir hesap açın.
2. Sağ üstteki **+** işaretine tıklayıp **"New repository"** seçin.
3. Depoya bir isim verin (örn. `mindflow-app`), **Public** seçin, "Create
   repository" düğmesine basın.
4. Açılan sayfada **"uploading an existing file"** bağlantısına tıklayın.
5. Bu zip dosyasının içeriğini bilgisayarınızda bir klasöre çıkarın
   (sağ tık → "Ayıkla / Extract"), sonra klasörün İÇİNDEKİ dosya ve
   klasörleri (kendisini değil) GitHub'ın açtığı yükleme alanına
   sürükleyip bırakın.
6. Sayfanın altındaki **"Commit changes"** düğmesine basın.

### 2. Adım — Codemagic'e bağlanın ve derlemeyi başlatın

1. [codemagic.io](https://codemagic.io) adresine gidin, **"Sign up"** ile
   ücretsiz hesap açın (GitHub hesabınızla giriş yapmanız en kolayı).
2. Codemagic, GitHub hesabınızdaki depoları görmek için izin isteyecek —
   izin verin.
3. Az önce oluşturduğunuz `mindflow-app` deposunu listeden seçin.
4. Codemagic, depodaki `codemagic.yaml` dosyasını otomatik olarak
   tanıyacak ve "MindFlow Android Build" adında bir iş akışı gösterecek.
5. **"Start new build"** düğmesine basın, "android-workflow" seçili
   olduğundan emin olup onaylayın.
6. Derleme yaklaşık 5-10 dakika sürer. Bittiğinde sayfada bir
   **"Artifacts"** bölümü çıkar — buradan `app-release.apk` dosyasını
   indirebilirsiniz.

### 3. Adım — Telefonunuza kurun

1. İndirdiğiniz `.apk` dosyasını telefonunuza aktarın (Google Drive,
   WhatsApp kendine mesaj, USB kablo — hangisi kolayınıza geliyorsa).
2. Telefonda dosyaya dokunduğunuzda Android "bilinmeyen kaynaklardan
   yükleme" izni isteyebilir — bu tamamen normal, MindFlow henüz Google
   Play'de olmadığı için bu şekilde kurulur. İzin verip kuruluma devam
   edin.

Bir adımda takılırsanız, ekran görüntüsü paylaşırsanız yardımcı olabilirim.

---

## Neden `android/` klasörü zip'in içinde yok?

Bu klasör tamamen otomatik üretilebilen kalıp (boilerplate) dosyalardan
oluşur ve hangi Flutter sürümüyle üretildiğine çok duyarlıdır. Elle
yazıp zip'e koymak yerine, `codemagic.yaml` her derlemede
`flutter create --platforms=android .` komutuyla bu klasörü **o anki
Codemagic Flutter sürümüne göre doğru şekilde** yeniden üretiyor. Bu,
sürüm uyuşmazlığından kaynaklanan derleme hatalarını baştan engelliyor.

---

## Mimari özeti

```
mindflow/
├── codemagic.yaml            # Ücretsiz bulut derleme yapılandırması
├── packages/
│   └── reading_engine/       # SAF DART — Flutter'a bağımlı değil.
│                              # Tokenizer + Chunker + Pacing kuralları +
│                              # RSVP oturum motoru burada. İleride bir
│                              # tarayıcı eklentisine taşınabilmesi için
│                              # kasıtlı olarak Flutter'dan ayrı tutuldu.
└── app/                      # Flutter uygulaması
    └── lib/
        ├── core/              # tema, dil sistemi, router, depolama, sabitler
        └── features/
            ├── onboarding/    # ilk açılışta dil seçimi
            ├── document_import/  # TXT/PDF/DOCX/Markdown/HTML ayrıştırıcılar
            ├── library/       # kütüphane ekranı
            ├── reader/        # RSVP okuma ekranı
            ├── bookmarks/      # yer imleri
            ├── stats/         # okuma istatistikleri
            ├── settings/      # tema, dil, hız ayarları
            └── ai/            # v1'de PASİF — ileride gerçek AI için arayüz hazır
```

**Depolama:** `sqflite` (kütüphane, belge blokları, yer imleri, okuma
geçmişi — ilişkisel veri) + `Hive` (ayarlar, "kaldığın yer" — hızlı
anahtar-değer verisi). İkisi de kod üretimi (build_runner) gerektirmez;
tek kurulum adımı `flutter pub get`.

**Diller:** Ayarlar ve ilk kurulum ekranında İngilizce, Türkçe, İspanyolca,
Almanca, Fransızca, Arapça seçilebilir (Arapça sağdan-sola otomatik
düzenlenir). Yeni bir dil eklemek `core/l10n/translations.dart` dosyasına
bir satır eklemek kadar basit.

**Yapay zeka:** v1'de yok — `features/ai/ai_provider.dart` içinde arayüz
tanımlı ama `NoopAiProvider` hiçbir şey yapmıyor. İleride gerçek bir AI
sağlayıcısı eklemek, bu arayüzü uygulayıp tek bir yerde (provider) takmak
kadar basit olacak.

## Yerel olarak çalıştırmak isterseniz (Flutter kuruluysa)

```bash
cd app
flutter create --platforms=android .   # android/ klasörünü üretir
flutter pub get
flutter run                             # veya: flutter build apk --release
```
