//
//  AIService.swift
//  Sehir-Rehberi
//
//  Created by Mustafa Devrim Yıldız on 18.12.2025.
//

import Foundation
import MapKit
import GoogleGenerativeAI

class AIService {

    let model = GenerativeModel(name: "gemini-pro", apiKey: "AIzaSyDqHfvZ-144f9qB8PBW0eXean6aJjoAuZg")
    
    // --- KEYWORD EXTRACTOR ---
    func extractSearchKeyword(userPreference: String, completion: @escaping (String) -> Void) {
        
        let lower = userPreference.lowercased()
        var fallbackKeyword = "Kafe"
        
        
        if lower.contains("eğlen") ||  lower.contains("parti") ||  lower.contains("bar"){
            fallbackKeyword = "Bar"
        } else if lower.contains("etkinlik") || lower.contains("canlı") || lower.contains("konser") || lower.contains("dans") || lower.contains("gece") || lower.contains("müzik"){
            fallbackKeyword = "Konser Alanı"
        }
        else if lower.contains("sessiz") || lower.contains("sakin") || lower.contains("kafa") || lower.contains("muhabbet") {
            if lower.contains("ders") || lower.contains("kitap") || lower.contains("çalış") {
                fallbackKeyword = "Kütüphane"
            }
            else if lower.contains("doğa") || lower.contains("hava") || lower.contains("doğayla"){
                fallbackKeyword = "Park"
            }else {
                fallbackKeyword = "Kafe"
            }
        }
        else if lower.contains("ders") || lower.contains("kitap") || lower.contains("çalış") ||  lower.contains("kütüphane"){
            fallbackKeyword = "Kütüphane"
        }
        else if lower.contains("doğa") || lower.contains("hava") || lower.contains("doğayla") ||  lower.contains("park"){
            fallbackKeyword = "Park"
        }
        else if lower.contains("tatlı") || lower.contains("pasta") { fallbackKeyword = "Pastane" }
        else if lower.contains("müzik") || lower.contains("bira") || lower.contains("alkol") ||  lower.contains("pub") ||  lower.contains("bar"){ fallbackKeyword = "Bar" }
        else if lower.contains("yemek") || lower.contains("açım") ||  lower.contains("restoran") ||  lower.contains("ac"){
            if lower.contains("avm") || lower.contains("alışveriş") { fallbackKeyword = "AVM" }
            else{
                fallbackKeyword = "Restoran" }
        }
        else if lower.contains("müze") || lower.contains("tarih") { fallbackKeyword = "Müze" }
        else if lower.contains("avm") || lower.contains("alışveriş") { fallbackKeyword = "AVM" }
        
        
        // --- AI PROMPT ---
        let prompt = """
        Kullanıcı tercihi: "\(userPreference)"
        
        Bu tercihi Apple Maps Türkiye kategorisine çevir. ŞU KURALLARA UY:
        
        1. Eğer kullanıcı "eğlenmek", "partilemek", "kopmak" istiyorsa -> "Bar" (Gece Kulübü) veya "Konser" seç.
        2. Eğer kullanıcı "sessiz", "sakin" bir yer istiyor ama "ders" veya "kitap" demiyorsa -> "Park" veya "Kafe" seç. Kütüphane seçme.
        3. Sadece "ders", "kitap", "sınav" kelimeleri varsa -> "Kütüphane" seç.
        4. "Gezmek", "tarih" -> "Tarihi" veya "Müze" seç.
        
        SADECE AŞAĞIDAKİ LİSTEDEN BİRİNİ YAZ:
        - Kütüphane
        - Pastane
        - Bar
        - Restoran
        - Park
        - Konser Alanı
        - Müze
        - Tarihi
        - AVM
        - Kafe
        
        Cevap:
        """
        
        Task {
            do {
                let response = try await model.generateContent(prompt)
                
                let rawText = response.text ?? fallbackKeyword
                let cleanedKeyword = rawText
                    .replacingOccurrences(of: "Cevap:", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\"", with: "")
                    .replacingOccurrences(of: ".", with: "")
                
                print("🎯 AI Kararı: \(cleanedKeyword) (Yedek: \(fallbackKeyword))")
                
                // Güvenlik kontrolü
                if cleanedKeyword.count > 15 {
                    DispatchQueue.main.async { completion(fallbackKeyword) }
                } else {
                    DispatchQueue.main.async { completion(cleanedKeyword) }
                }
            } catch {
                print("⚠️ AI Hatası: \(error)")
                DispatchQueue.main.async { completion(fallbackKeyword) }
            }
        }
    }
    
    // --- NİYET ANALİZİ ---
    func analyzeUserIntent(userResponse: String, completion: @escaping (Bool) -> Void) {
        let lower = userResponse.lowercased()
        let positives = ["evet", "tamam", "olur", "hemen", "gidelim", "aç", "harita", "göster", "yess", "aynen", "tabi","yes","olabilir","okey"]
        if positives.contains(where: lower.contains) { completion(true); return }
        
        let prompt = "Cevap: \"\(userResponse)\". Kabul mü (POSITIVE) Red mi (NEGATIVE)? Tek kelime."
        Task {
            do {
                let res = try await model.generateContent(prompt)
                let txt = res.text?.uppercased() ?? "NEGATIVE"
                DispatchQueue.main.async { completion(txt.contains("POSITIVE")) }
            } catch { DispatchQueue.main.async { completion(false) } }
        }
    }
    
    // --- RAG MOTORU ---
    private func formatCafesToText(mapItems: [MKMapItem], userLocation: CLLocationCoordinate2D) -> String {
        var text = "Mekanlar:\n"
        for item in mapItems { text += "- \(item.name ?? "")\n" }
        return text
    }
    
    func askAI(userQuestion: String, visibleCafes: [MKMapItem], userLocation: CLLocationCoordinate2D, completion: @escaping (String) -> Void) {
        let context = formatCafesToText(mapItems: visibleCafes, userLocation: userLocation)
        let prompt = "Soru: \(userQuestion)\nMekanlar:\n\(context)\nÖnerin nedir? Türkçe cevapla."
        Task {
            do {
                let res = try await model.generateContent(prompt)
                DispatchQueue.main.async { completion(res.text ?? "...") }
            } catch { DispatchQueue.main.async { completion("Hata.") } }
        }
    }
}
