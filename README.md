AI Destekli Şehir Rehberi (iOS)

Bu proje, kullanıcının o anki ruh haline veya isteğine göre (örn: "Kafa dinlemek istiyorum", "Canlı müzik dinlemek istiyorum") Google Gemini AI kullanarak niyeti analiz eden ve Apple Haritalar (MapKit) üzerinde en uygun mekanları listeleyen akıllı bir iOS uygulamasıdır.

---Özellikler---

Yapay Zeka Destekli Niyet Analizi: Kullanıcı "Ders çalışacağım" dediğinde Kütüphane, "Eğlenmek istiyorum" dediğinde Bar veya Konser alanı önerir. (Google Gemini API).
Akıllı Kategori Eşleştirme: 10 farklı kategori (Kafe, Restoran, Müze, AVM, Tarihi Yerler, Park vb.) arasında otomatik geçiş yapar.
Gelişmiş Filtreleme:
"Park" ararken otoparkları (İspark vb.) eler.
"Konser" ararken müzik kurslarını veya düğün salonlarını eler.
Mesafe Sınırı: Kullanıcıyı yormamak için sadece 30 dakika yürüme mesafesindeki (max 2.5 km) yerleri gösterir.
Dinamik Konum Seçimi: Haritaya uzun basarak istenilen bölgede arama yapılabilir.
Navigasyon: Seçilen mekana yürüyerek veya araçla ne kadar sürede gidileceğini hesaplar ve Apple Haritalar üzerinden rota çizer.

---Kullanılan Teknolojiler---

Dil: Swift
UI: UIKit
Harita: MapKit, CoreLocation
Yapay Zeka: Google Generative AI SDK (Gemini Pro)
Versiyon Kontrol: Git & GitHub

---Kurulum ve Çalıştırma---

Bu projeyi kendi bilgisayarınızda çalıştırmak için adımları izleyin:

1. Projeyi Klonlayın
Terminali açın ve projeyi bilgisayarınıza indirin:
git clone https://github.com/mustafadevrim/AI-Sehir-Rehberi-iOS-App
cd AI-Sehir-Rehberi-iOS-App

2. Google Gemini API Key Alın
Uygulamanın çalışması için bir API anahtarına ihtiyacınız var:
Google AI Studio adresine gidin.
"Get API Key" diyerek yeni bir anahtar oluşturun.

3. API Key'i Ekleyin
Proje dosyasını Xcode ile açın. AIService.swift dosyasını bulun ve şu satıra kendi anahtarınızı yapıştırın:
let model = GenerativeModel(name: "gemini-pro", apiKey: "BURAYA_SIZIN_API_KEYINIZ")

4. Çalıştırın
Xcode'da CMD + R tuşlarına basarak simülatörde başlatın.
İlk açılışta Konum İznini onaylayın.

---Nasıl Kullanılır?---
1-Sohbet Edin: "Ders çalışıcağım sessiz bir yer arıyorum" veya "Şuan acıktığımı hissediyorum" vb cümleler yazın.
2-AI Karar Versin: Yapay zeka bunu "Kütüphane" "Restoran" olarak yorumlayacaktır.
3-Keşfedin: Haritada size en yakın ve en uygun yerler pinlenecektir.
4-Rota Çizin: Bir mekana tıklayarak yürüme/araç süresini görün ve navigasyonu başlatın.
