//
//  Views.swift
//  HYD
//
//  Created by Vladyslav Lysyy on 6/12/25.
//

import SwiftUI
import SwiftData
import PhotosUI

// MARK: - 1. PANTALLA DE BIENVENIDA (Smooth & Small Emojis)
struct WelcomeView: View {
    @EnvironmentObject var appManager: AppManager
    @State private var phase = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                if phase >= 0 {
                    Text(phase == 0 ? "Hola" : "How is your day?")
                        .font(.system(size: phase == 0 ? 50 : 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .transition(.opacity.combined(with: .scale))
                        .id("TitleText")
                }
                
                if phase == 2 {
                    HStack(spacing: 15) {
                        ForEach(Mood.allCases, id: \.self) { mood in
                            Text(mood.rawValue)
                                .font(.system(size: 35))
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .scaleEffect(1.0)
                                .onTapGesture {
                                    appManager.setMood(mood)
                                }
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: phase)
        }
        .onAppear {
            // "Hola" dura 2 segundos
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation { phase = 1 }
            }
        }
        .onTapGesture {
            if phase == 1 { phase = 2 }
        }
    }
}

// MARK: - 2. DASHBOARD PRINCIPAL
struct DashboardView: View {
    @EnvironmentObject var appManager: AppManager
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<ReminderItem> { !$0.isCompleted }, sort: \ReminderItem.date) private var activeReminders: [ReminderItem]
    
    @State private var aiInputText = ""
    @State private var showAIAlert = false
    @State private var tempAIResult: AIService.AIResult?
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [appManager.accentColor.opacity(0.2), .black], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                if appManager.showConfetti {
                    ConfettiView().allowsHitTesting(false).zIndex(10)
                }
                
                ScrollView {
                    VStack(spacing: 25) {
                        // A. HEADER PERFIL (Con Foto Real)
                        NavigationLink(destination: ProfileView()) {
                            HStack {
                                // Lógica para mostrar foto o placeholder
                                if let data = appManager.profileImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                                } else {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .foregroundStyle(.gray.opacity(0.5))
                                        .frame(width: 50, height: 50)
                                        .background(Circle().fill(.white.opacity(0.1)))
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(appManager.userName)
                                        .font(.title3).bold().foregroundStyle(.white)
                                    Text(appManager.currentRank.rawValue)
                                        .font(.caption).bold().foregroundStyle(appManager.accentColor)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("\(appManager.currentPoints) pts")
                                        .foregroundStyle(.white)
                                        .font(.caption)
                                    ProgressView(value: Double(appManager.currentPoints % 100), total: 100)
                                        .frame(width: 80)
                                        .tint(appManager.accentColor)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // B. ESTADÍSTICAS
                        NavigationLink(destination: StatsDetailView()) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Esta Semana").font(.headline).foregroundStyle(.gray)
                                    Text("Ver detalles").font(.caption).foregroundStyle(.white.opacity(0.7))
                                }
                                Spacer()
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.title)
                                    .foregroundStyle(appManager.accentColor)
                            }
                            .glassStyle()
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // C. SMART INPUT IA
                        VStack(alignment: .leading) {
                            Text("✨ HYD AI").font(.caption).bold().foregroundStyle(appManager.accentColor)
                            HStack {
                                TextField("Escribe aquí...", text: $aiInputText)
                                    .submitLabel(.done)
                                    .onSubmit { processAI() }
                                    .foregroundStyle(.white)
                                
                                Button(action: processAI) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(appManager.accentColor)
                                }
                            }
                        }
                        .glassStyle()
                        
                        // D. LISTA DE PENDIENTES
                        if !activeReminders.isEmpty {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Próximos").font(.title3).bold().foregroundStyle(.white)
                                    .transition(.opacity)
                                
                                ForEach(activeReminders) { item in
                                    HStack {
                                        Image(systemName: "circle")
                                            .font(.title2)
                                            .foregroundStyle(.white)
                                            .onTapGesture {
                                                appManager.completeTask(item: item)
                                            }
                                        
                                        VStack(alignment: .leading) {
                                            Text(item.title).foregroundStyle(.white)
                                            Text(item.date.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption).foregroundStyle(.gray)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    Divider().background(.white.opacity(0.2))
                                }
                            }
                            .glassStyle()
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding()
                }
            }
            .alert("IA Sugerencia", isPresented: $showAIAlert) {
                Button("Añadir") {
                    if let res = tempAIResult {
                        let newItem = ReminderItem(title: res.title, date: res.date, type: res.type)
                        modelContext.insert(newItem)
                        NotificationManager.shared.scheduleNotifications(for: newItem)
                        aiInputText = ""
                    }
                }
                Button("Cancelar", role: .cancel) { }
            } message: {
                if let res = tempAIResult {
                    Text("Crear '\(res.title)' para el \(res.date.formatted())?")
                }
            }
        }
    }
    
    func processAI() {
        guard !aiInputText.isEmpty else { return }
        if let result = AIService.shared.analyzeInput(aiInputText) {
            tempAIResult = result
            showAIAlert = true
        }
    }
}

// MARK: - 3. VISTA DE PERFIL (SELECTOR DE FOTOS)
struct ProfileView: View {
    @EnvironmentObject var appManager: AppManager
    @State private var selectedItem: PhotosPickerItem? = nil
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 30) {
                
                // --- SELECTOR DE FOTO ---
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    ZStack {
                        if let data = appManager.profileImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(appManager.accentColor, lineWidth: 2))
                        } else {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 120, height: 120)
                                .foregroundStyle(.gray)
                        }
                        
                        // Icono pequeño de cámara
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "camera.fill")
                                    .foregroundStyle(.white)
                                    .padding(8)
                                    .background(appManager.accentColor)
                                    .clipShape(Circle())
                            }
                        }
                        .frame(width: 120, height: 120)
                    }
                }
                .onChange(of: selectedItem) { oldValue, newItem in
                    Task {
                        // Convertir la selección a Data y guardarla
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            // Comprimir si es necesario o guardar directo
                            DispatchQueue.main.async {
                                appManager.profileImageData = data
                            }
                        }
                    }
                }
                
                // Nombre Editable
                VStack(alignment: .leading) {
                    Text("Tu Nombre").font(.caption).foregroundStyle(.gray)
                    TextField("Nombre", text: $appManager.userName)
                        .font(.title)
                        .foregroundStyle(.white)
                        .padding(.bottom, 5)
                        .overlay(Rectangle().frame(height: 1).padding(.top, 35).foregroundStyle(.gray), alignment: .bottom)
                }
                .padding(.horizontal, 40)
                
                // Rango
                VStack(spacing: 10) {
                    Text("Nivel Actual").font(.headline).foregroundStyle(.gray)
                    Text(appManager.currentRank.rawValue)
                        .font(.largeTitle).bold()
                        .foregroundStyle(appManager.accentColor)
                        .shadow(color: appManager.accentColor.opacity(0.5), radius: 10)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .navigationTitle("Mi Perfil")
    }
}

// MARK: - 4. VISTA DE ESTADÍSTICAS (Calculada)
struct StatsDetailView: View {
    @EnvironmentObject var appManager: AppManager
    
    @Query(filter: #Predicate<ReminderItem> { $0.isCompleted }, sort: \ReminderItem.date, order: .reverse) private var history: [ReminderItem]
    @Query(filter: #Predicate<ReminderItem> { !$0.isCompleted }) private var activeItems: [ReminderItem]
    
    var completionPercentage: Double {
        let total = history.count + activeItems.count
        if total == 0 { return 0.0 }
        return Double(history.count) / Double(total)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Productividad").font(.headline).foregroundStyle(.gray)
                            Text("\(Int(completionPercentage * 100))%")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("\(history.count) terminadas de \(history.count + activeItems.count)")
                                .font(.caption).foregroundStyle(.gray)
                        }
                        Spacer()
                        ZStack {
                            Circle().stroke(.white.opacity(0.1), lineWidth: 10)
                            Circle()
                                .trim(from: 0, to: completionPercentage)
                                .stroke(appManager.accentColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.easeOut(duration: 1.0), value: completionPercentage)
                        }
                        .frame(width: 80, height: 80)
                    }
                    .glassStyle()
                    
                    Text("Historial (Se borra en 7 días)").font(.caption).foregroundStyle(.gray).padding(.top)
                    
                    if history.isEmpty {
                        Text("Aún no has completado nada esta semana.")
                            .foregroundStyle(.gray)
                            .padding()
                    } else {
                        ForEach(history) { item in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(appManager.accentColor)
                                VStack(alignment: .leading) {
                                    Text(item.title)
                                        .strikethrough()
                                        .foregroundStyle(.white.opacity(0.6))
                                    Text("Completado: \(item.date.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption).foregroundStyle(.gray)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Estadísticas")
    }
}
