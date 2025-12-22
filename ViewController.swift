//
//  ViewController.swift
//  Sehir-Rehberi
//
//  Created by Mustafa Devrim Yıldız on 18.12.2025.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    // --- DEĞİŞKENLER ---
    private let aiService = AIService()
    private var userCafePreference: String = ""
    private var searchKeyword: String = "Kafe"
    
    private var isRouting = false
    private var isCustomLocationMode = false
    private var lastCustomCoordinate: CLLocationCoordinate2D?
    private let locationManager = CLLocationManager()
    
    enum ChatState {
        case askingPreference
        case waitingForConfirmation
    }
    private var currentChatState: ChatState = .askingPreference

    // --- UI ELEMENTS ---
    
    private let welcomeView: UIView = {
        let v = UIView(); v.backgroundColor = .white; v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let welcomeTitle: UILabel = {
        let l = UILabel(); l.text = "AI Şehir Rehberi"; l.font = .boldSystemFont(ofSize: 32); l.textColor = .black; l.textAlignment = .center; l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let welcomeIcon: UIImageView = {
        let iv = UIImageView(); iv.image = UIImage(systemName: "brain.head.profile"); iv.tintColor = .systemIndigo; iv.contentMode = .scaleAspectFit; iv.translatesAutoresizingMaskIntoConstraints = false; return iv
    }()
    private let startButton: UIButton = {
        let b = UIButton(type: .system); b.setTitle("Hadi Gideceğin Yeri Seçelim 🚀", for: .normal); b.backgroundColor = .systemIndigo;b.setTitleColor(.white, for: .normal); b.layer.cornerRadius = 12; b.translatesAutoresizingMaskIntoConstraints = false; return b
    }()
    
    private let chatView: UIView = {
        let v = UIView(); v.backgroundColor = .systemGray6; v.isHidden = true; v.translatesAutoresizingMaskIntoConstraints = false; return v
    }()
    private let botLabel: UILabel = {
        let l = UILabel(); l.text = "..."; l.font = .systemFont(ofSize: 18, weight: .medium); l.textColor = .black; l.numberOfLines = 0; l.textAlignment = .center; l.translatesAutoresizingMaskIntoConstraints = false; return l
    }()
    private let userTextField: UITextField = {
        let t = UITextField(); t.placeholder = "Cevabınızı buraya yazın..."; t.borderStyle = .roundedRect; t.backgroundColor = .white; t.translatesAutoresizingMaskIntoConstraints = false; return t
    }()
    private let sendButton: UIButton = {
        let b = UIButton(type: .system); b.setImage(UIImage(systemName: "paperplane.fill"), for: .normal); b.tintColor = .white; b.backgroundColor = .systemIndigo; b.layer.cornerRadius = 10; b.translatesAutoresizingMaskIntoConstraints = false; return b
    }()
    private let closeChatButton: UIButton = {
        let b = UIButton(type: .system); b.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal); b.tintColor = .systemGray; b.translatesAutoresizingMaskIntoConstraints = false; return b
    }()
    
    private let mapView: MKMapView = {
        let m = MKMapView(); m.showsUserLocation = true; m.translatesAutoresizingMaskIntoConstraints = false; return m
    }()
    private let aiButton: UIButton = {
        let b = UIButton(type: .system); b.setImage(UIImage(systemName: "sparkles"), for: .normal); b.backgroundColor = .black; b.tintColor = .white; b.layer.cornerRadius = 25; b.translatesAutoresizingMaskIntoConstraints = false; return b
    }()
    private let menuButton: UIButton = {
        let b = UIButton(type: .system); b.setTitle("Menü", for: .normal); b.backgroundColor = .black; b.setTitleColor(.white, for: .normal); b.layer.cornerRadius = 8; b.translatesAutoresizingMaskIntoConstraints = false; b.isHidden = true; return b
    }()
    private let zoomInButton: UIButton = {
        let b = UIButton(type: .system); b.setTitle("+", for: .normal); b.titleLabel?.font = .boldSystemFont(ofSize: 24); b.backgroundColor = .white; b.layer.cornerRadius = 20; b.translatesAutoresizingMaskIntoConstraints = false; return b
    }()
    private let zoomOutButton: UIButton = {
        let b = UIButton(type: .system); b.setTitle("-", for: .normal); b.titleLabel?.font = .boldSystemFont(ofSize: 24); b.backgroundColor = .white; b.layer.cornerRadius = 20; b.translatesAutoresizingMaskIntoConstraints = false; return b
    }()

    // --- LIFECYCLE ---
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
    }
    
    // --- UI SETUP ---
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(mapView); view.addSubview(aiButton); view.addSubview(menuButton); view.addSubview(zoomInButton); view.addSubview(zoomOutButton)
        view.addSubview(chatView); chatView.addSubview(closeChatButton); chatView.addSubview(botLabel); chatView.addSubview(userTextField); chatView.addSubview(sendButton)
        view.addSubview(welcomeView); welcomeView.addSubview(welcomeIcon); welcomeView.addSubview(welcomeTitle); welcomeView.addSubview(startButton)
        
        setupConstraints()
        
        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
        aiButton.addTarget(self, action: #selector(aiTapped), for: .touchUpInside)
        closeChatButton.addTarget(self, action: #selector(closeChatTapped), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        menuButton.addTarget(self, action: #selector(menuTapped), for: .touchUpInside)
        zoomInButton.addTarget(self, action: #selector(zoomInTapped), for: .touchUpInside)
        zoomOutButton.addTarget(self, action: #selector(zoomOutTapped), for: .touchUpInside)
        
        mapView.delegate = self
        locationManager.delegate = self
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor), mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor), mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor), mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            aiButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20), aiButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30), aiButton.widthAnchor.constraint(equalToConstant: 50), aiButton.heightAnchor.constraint(equalToConstant: 50),
            menuButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10), menuButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            zoomOutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20), zoomOutButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 40), zoomOutButton.widthAnchor.constraint(equalToConstant: 40), zoomOutButton.heightAnchor.constraint(equalToConstant: 40),
            zoomInButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20), zoomInButton.bottomAnchor.constraint(equalTo: zoomOutButton.topAnchor, constant: -10), zoomInButton.widthAnchor.constraint(equalToConstant: 40), zoomInButton.heightAnchor.constraint(equalToConstant: 40),
            
            chatView.topAnchor.constraint(equalTo: view.topAnchor), chatView.bottomAnchor.constraint(equalTo: view.bottomAnchor), chatView.leadingAnchor.constraint(equalTo: view.leadingAnchor), chatView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            closeChatButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10), closeChatButton.trailingAnchor.constraint(equalTo: chatView.trailingAnchor, constant: -20), closeChatButton.widthAnchor.constraint(equalToConstant: 40), closeChatButton.heightAnchor.constraint(equalToConstant: 40),
            botLabel.centerYAnchor.constraint(equalTo: chatView.centerYAnchor, constant: -50), botLabel.leadingAnchor.constraint(equalTo: chatView.leadingAnchor, constant: 30), botLabel.trailingAnchor.constraint(equalTo: chatView.trailingAnchor, constant: -30),
            userTextField.topAnchor.constraint(equalTo: botLabel.bottomAnchor, constant: 20), userTextField.leadingAnchor.constraint(equalTo: chatView.leadingAnchor, constant: 30), userTextField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10), userTextField.heightAnchor.constraint(equalToConstant: 50),
            sendButton.centerYAnchor.constraint(equalTo: userTextField.centerYAnchor), sendButton.trailingAnchor.constraint(equalTo: chatView.trailingAnchor, constant: -20), sendButton.widthAnchor.constraint(equalToConstant: 50), sendButton.heightAnchor.constraint(equalToConstant: 50),
            
            welcomeView.topAnchor.constraint(equalTo: view.topAnchor), welcomeView.bottomAnchor.constraint(equalTo: view.bottomAnchor), welcomeView.leadingAnchor.constraint(equalTo: view.leadingAnchor), welcomeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            welcomeIcon.centerXAnchor.constraint(equalTo: welcomeView.centerXAnchor), welcomeIcon.centerYAnchor.constraint(equalTo: welcomeView.centerYAnchor, constant: -100), welcomeIcon.widthAnchor.constraint(equalToConstant: 120), welcomeIcon.heightAnchor.constraint(equalToConstant: 120),
            welcomeTitle.topAnchor.constraint(equalTo: welcomeIcon.bottomAnchor, constant: 30), welcomeTitle.centerXAnchor.constraint(equalTo: welcomeView.centerXAnchor),
            startButton.bottomAnchor.constraint(equalTo: welcomeView.safeAreaLayoutGuide.bottomAnchor, constant: -250), startButton.centerXAnchor.constraint(equalTo: welcomeView.centerXAnchor), startButton.widthAnchor.constraint(equalToConstant: 250), startButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }
    
    // --- ACTIONS ---
    
    @objc func startTapped() {
        UIView.animate(withDuration: 0.3, animations: { self.welcomeView.alpha = 0 }) { _ in
            self.welcomeView.removeFromSuperview()
            self.chatView.isHidden = false
            self.botLabel.text = "Merhaba! Ne tarz bir mekana gitmek istersiniz?"
            self.currentChatState = .askingPreference
        }
    }
    
    @objc func aiTapped() {
        chatView.isHidden = false; chatView.alpha = 0; botLabel.text = "Fikriniz mi değişti? Ne tarz bir yer arayalım?"; currentChatState = .askingPreference; UIView.animate(withDuration: 0.3) { self.chatView.alpha = 1 }
    }
    
    @objc func closeChatTapped() {
        UIView.animate(withDuration: 0.3, animations: { self.chatView.alpha = 0 }) { _ in
            self.chatView.isHidden = true
            if self.locationManager.authorizationStatus == .notDetermined { self.setupLocationManager(); self.showSelectionAlert() }
        }
    }
    
    @objc func menuTapped() {
        let alert = UIAlertController(title: "Menü", message: "İşlem seçin", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "📍 Konum Değiştir", style: .default, handler: { _ in
            self.mapView.removeAnnotations(self.mapView.annotations); self.mapView.removeOverlays(self.mapView.overlays); self.menuButton.isHidden = true; self.showSelectionAlert()
        }))
        alert.addAction(UIAlertAction(title: "🤖 Yeni Arama Yap", style: .default, handler: { _ in
            self.menuButton.isHidden = true; self.aiTapped()
        }))
        alert.addAction(UIAlertAction(title: "İptal", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc func sendTapped() {
        guard let text = userTextField.text, !text.isEmpty else { return }
        userTextField.text = ""; userTextField.resignFirstResponder()
        
        switch currentChatState {
        case .askingPreference:
            userCafePreference = text
            botLabel.text = "Analiz ediliyor..."
            aiService.extractSearchKeyword(userPreference: text) { keyword in
                self.searchKeyword = keyword
                self.botLabel.text = "Anladım. \"\(keyword)\" kategorisini sizin için arayacağım. Sizin için de uygunsa, \nharitaya geçip mekanları gösterelim mi?"
                self.currentChatState = .waitingForConfirmation
            }
        case .waitingForConfirmation:
            botLabel.text = "..."
            aiService.analyzeUserIntent(userResponse: text) { isPositive in
                if isPositive {
                    self.botLabel.text = "Harika! Harita açılıyor..."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.transitionToMap() }
                } else {
                    self.botLabel.text = "Peki, ne istersin?"; self.currentChatState = .askingPreference
                }
            }
        }
    }
    
    func transitionToMap() {
        UIView.animate(withDuration: 0.5, animations: { self.chatView.alpha = 0 }) { _ in
            self.chatView.isHidden = true
            self.setupLocationManager()
            self.showSelectionAlert()
        }
    }
    
    @objc func zoomInTapped() { var r = mapView.region; r.span.latitudeDelta /= 2; r.span.longitudeDelta /= 2; mapView.setRegion(r, animated: true) }
    @objc func zoomOutTapped() { var r = mapView.region; r.span.latitudeDelta *= 2; r.span.longitudeDelta *= 2; mapView.setRegion(r, animated: true) }

    // --- MAP LOGIC ---
    
    func setupGestures() { let lp = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress)); lp.minimumPressDuration = 1.0; mapView.addGestureRecognizer(lp) }
    func setupLocationManager() { locationManager.delegate = self; locationManager.desiredAccuracy = kCLLocationAccuracyBest; checkLocationAuthorization() }
    func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: mapView.showsUserLocation = true; locationManager.startUpdatingLocation()
        case .notDetermined: locationManager.requestWhenInUseAuthorization()
        default: break
        }
    }
    
    func showSelectionAlert() {
        let ac = UIAlertController(title: "Konum", message: "Nerede arayalım?", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Mevcut Konum", style: .default, handler: { _ in
            self.isCustomLocationMode = false; self.lastCustomCoordinate = nil
            self.locationManager.startUpdatingLocation()
        }))
        ac.addAction(UIAlertAction(title: "Haritadan Seçeceğim", style: .default, handler: { _ in
            self.isCustomLocationMode = true; self.showToast(message: "Haritaya basılı tutun")
        }))
        present(ac, animated: true)
    }
    
    // --- SEARCH LOGIC  ---
        private func searchCafes(at coord: CLLocationCoordinate2D, customKeyword: String? = nil) {
            
            let oldAnnotations = mapView.annotations.filter {
                !($0 is MKUserLocation) && $0.title != "Seçilen Konum"
            }
            mapView.removeAnnotations(oldAnnotations)
            
            let keyword = customKeyword ?? self.searchKeyword
            self.showToast(message: " Aranan: \(keyword) (Max 30 dk yürüme)")
            
            // Arama Terimini Belirle
            var query = keyword
            if keyword == "Konser" { query = "Canlı Müzik" }
            else if keyword == "AVM" { query = "Alışveriş Merkezi" }
            else if keyword == "Tarihi" { query = "Tarihi Yerler" }
            
            let req = MKLocalSearch.Request()
            req.naturalLanguageQuery = query
            
            
            req.region = MKCoordinateRegion(center: coord, latitudinalMeters: 4000, longitudinalMeters: 4000)
            
            // Kategori Filtreleri
            if keyword == "Park" { req.pointOfInterestFilter = MKPointOfInterestFilter(including: [.park, .beach, .nationalPark]) }
            else if keyword == "Konser" { req.pointOfInterestFilter = MKPointOfInterestFilter(including: [.theater, .nightlife]) }
            else if keyword == "Müze" { req.pointOfInterestFilter = MKPointOfInterestFilter(including: [.museum]) }
            else if keyword == "AVM" { req.pointOfInterestFilter = MKPointOfInterestFilter(including: [.store]) }
            else if keyword == "Tarihi" { req.pointOfInterestFilter = MKPointOfInterestFilter(including: [.landmark, .museum]) }
            
            MKLocalSearch(request: req).start { resp, _ in
                guard let resp = resp else { return }
                let centerLoc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                
                DispatchQueue.main.async {
                    var foundCount = 0
                    for item in resp.mapItems {
                        let name = item.name ?? ""
                        let lowerName = name.lowercased()
                        let category = item.pointOfInterestCategory
                        
                        // --- MESAFE KONTROLÜ ---
                        guard let loc = item.placemark.location else { continue }
                        let dist = loc.distance(from: centerLoc) // Metre cinsinden mesafe
                        
                        if dist > 1500 {
                            continue
                        }
                        
                        // --- KATEGORİ FİLTRELEME  ---
                        if keyword == "Park" {
                            if lowerName.contains("ispark") || lowerName.contains("otopark") || lowerName.contains("garage") || lowerName.contains("parking") { continue }
                            if category == .parking { continue }
                        }
                        if keyword == "Kütüphane" {
                            if lowerName.contains("kırtasiye") || lowerName.contains("fotokopi") { continue }
                        }
                        if keyword == "Konser" {
                            if lowerName.contains("kurs") || lowerName.contains("ders") || lowerName.contains("akademi") || lowerName.contains("satış") || lowerName.contains("shop") || lowerName.contains("düğün") { continue }
                        }
                        if keyword == "Müze" {
                             if lowerName.contains("shop") || lowerName.contains("mağaza") { continue }
                        }
                        
                        // --- HARİTAYA EKLE ---
                        let mins = Int(dist / 80)
                        let ann = MKPointAnnotation()
                        ann.title = item.name
                       
                        ann.subtitle = "🚶 ~\(mins) dk yürüme (\(Int(dist))m)"
                        ann.coordinate = loc.coordinate
                        self.mapView.addAnnotation(ann)
                        foundCount += 1
                    }
                    
                    if foundCount == 0 { self.showToast(message: "30 dk yürüme mesafesinde \(keyword) yok.") }
                }
            }
        }
    
    @objc func handleLongPress(_ g: UILongPressGestureRecognizer) {
        if !isCustomLocationMode || g.state != .began { return }
        
        let coord = mapView.convert(g.location(in: mapView), toCoordinateFrom: mapView)
        lastCustomCoordinate = coord
        
        
        let oldSelections = mapView.annotations.filter { $0.title == "Seçilen Konum" }
        mapView.removeAnnotations(oldSelections)
        
        let ann = MKPointAnnotation(); ann.coordinate = coord; ann.title = "Seçilen Konum"; mapView.addAnnotation(ann)
        
        searchCafes(at: coord, customKeyword: self.searchKeyword)
        menuButton.isHidden = false
    }
    
    func focusMap(_ coord: CLLocationCoordinate2D) {
        let reg = MKCoordinateRegion(center: coord, latitudinalMeters: 4000, longitudinalMeters: 4000)
        mapView.setRegion(reg, animated: true)
    }
    
    // --- ROTA & UIs ---
    func drawRouteAndCalculate(to dest: CLLocationCoordinate2D, name: String, from source: CLLocationCoordinate2D? = nil) {
        isRouting = true; mapView.removeOverlays(mapView.overlays)
        
        let sItem: MKMapItem
        if let src = source {
            sItem = MKMapItem(placemark: MKPlacemark(coordinate: src))
            sItem.name = "İşaretli Konum"
        } else {
            sItem = MKMapItem.forCurrentLocation()
        }
        
        let dItem = MKMapItem(placemark: MKPlacemark(coordinate: dest)); dItem.name = name
        
        let grp = DispatchGroup(); var wStr="", dStr=""
        grp.enter(); let wr = MKDirections.Request(); wr.source = sItem; wr.destination = dItem; wr.transportType = .walking
        MKDirections(request: wr).calculate { r, _ in if let t = r?.routes.first?.expectedTravelTime { wStr = "\(Int(t/60)) dk" }; grp.leave() }
        
        grp.enter(); let dr = MKDirections.Request(); dr.source = sItem; dr.destination = dItem; dr.transportType = .automobile
        MKDirections(request: dr).calculate { r, _ in
            if let rt = r?.routes.first {
                dStr = "\(Int(rt.expectedTravelTime/60)) dk"
                self.mapView.addOverlay(rt.polyline)
                self.mapView.setVisibleMapRect(rt.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top:50, left:50, bottom:50, right:50), animated: true)
            }
            grp.leave()
        }
        
        grp.notify(queue: .main) {
            self.showNavAlert(name: name, walk: wStr, drive: dStr, destItem: dItem, sourceItem: sItem)
            self.isRouting = false
        }
    }
    
    func showNavAlert(name: String, walk: String, drive: String, destItem: MKMapItem, sourceItem: MKMapItem) {
        let ac = UIAlertController(title: name, message: "🚶ortalama \(walk)\n🚗 ortalama \(drive)", preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Apple Maps'te Aç (Navigasyon)", style: .default, handler: { _ in
            MKMapItem.openMaps(with: [sourceItem, destItem], launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        }))
        ac.addAction(UIAlertAction(title: "Tamam", style: .cancel))
        self.present(ac, animated: true)
    }
    
    func showToast(message: String) {
        let l = UILabel(frame: CGRect(x: view.frame.width/2-140, y: view.frame.height-140, width: 280, height: 40))
        l.backgroundColor = UIColor.black.withAlphaComponent(0.8); l.textColor = .white; l.textAlignment = .center; l.text = message; l.layer.cornerRadius = 10; l.clipsToBounds = true; l.font = .boldSystemFont(ofSize: 14)
        view.addSubview(l); UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: { l.alpha = 0 }, completion: { _ in l.removeFromSuperview() })
    }
}

// --- EXTENSIONS ---

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        
        focusMap(loc.coordinate)
        
        if !isCustomLocationMode {
            searchCafes(at: loc.coordinate, customKeyword: self.searchKeyword)
            menuButton.isHidden = false
        }
        
        manager.stopUpdatingLocation()
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if view.annotation is MKUserLocation || view.annotation?.title == "Seçilen Konum" { return }
        guard let ann = view.annotation else { return }
        let title = ann.title! ?? "Mekan"; let coord = ann.coordinate
        
        if isCustomLocationMode, let start = lastCustomCoordinate {
            let ac = UIAlertController(title: "Rota", message: "Nereden?", preferredStyle: .actionSheet)
            ac.addAction(UIAlertAction(title: "İşaretli Yerden", style: .default, handler: { _ in self.drawRouteAndCalculate(to: coord, name: title, from: start) }))
            ac.addAction(UIAlertAction(title: "Mevcut Konumdan", style: .default, handler: { _ in self.drawRouteAndCalculate(to: coord, name: title, from: nil) }))
            ac.addAction(UIAlertAction(title: "İptal", style: .cancel)); present(ac, animated: true)
        } else {
            drawRouteAndCalculate(to: coord, name: title, from: nil)
        }
        mapView.deselectAnnotation(ann, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let p = overlay as? MKPolyline { let r = MKPolylineRenderer(polyline: p); r.strokeColor = .systemBlue; r.lineWidth = 5; return r }
        return MKOverlayRenderer()
    }
}


