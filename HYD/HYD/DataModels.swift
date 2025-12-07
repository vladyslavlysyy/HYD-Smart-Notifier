//
//  DataModels.swift
//  HYD
//
//  Created by Vladyslav Lysyy on 6/12/25.
//

import Combine
import Foundation
import SwiftData
import SwiftUI

// MARK: - Enums
enum Mood: String, CaseIterable, Codable {
    case angry = "😡", sad = "😢", normal = "😐", happy = "😄", energized = "⚡️"
    
    var themeColor: Color {
        switch self {
        case .happy: return .green
        case .sad: return .gray
        case .normal: return .yellow
        case .angry: return .red
        case .energized: return .purple
        }
    }
}

enum TaskType: String, Codable, CaseIterable {
    case event = "Evento", appointment = "Cita", homework = "Deber", reminder = "Recordatorio"
    
    var basePoints: Int {
        switch self {
        case .appointment: return 5; case .event: return 10; case .homework: return 15; case .reminder: return 5
        }
    }
}

enum UserRank: String, CaseIterable {
    case beginner = "Beginner", apprentice = "Apprentice", responsible = "Responsible", hardWorker = "Hard Worker", proAchiever = "Pro Achiever", master = "Master", titan = "Titan", legendary = "Legendary", mythic = "Mythic", eternal = "Eternal"
    
    static func getRank(points: Int) -> UserRank {
        switch points {
        case 0..<10: return .beginner; case 10..<50: return .apprentice; case 50..<100: return .responsible; case 100..<200: return .hardWorker; case 200..<500: return .proAchiever; case 500..<1000: return .master; case 1000..<2000: return .titan; case 2000..<5000: return .legendary; case 5000..<10000: return .mythic; default: return .eternal
        }
    }
}

// MARK: - Modelo de Datos
@Model
final class ReminderItem {
    var id: UUID
    var title: String
    var date: Date
    var typeString: String
    var isCompleted: Bool
    var completedDate: Date? // Para saber cuándo borrarlo del historial
    
    init(title: String, date: Date, type: TaskType) {
        self.id = UUID()
        self.title = title
        self.date = date
        self.typeString = type.rawValue
        self.isCompleted = false
    }
    
    var type: TaskType { TaskType(rawValue: typeString) ?? .reminder }
}

// MARK: - App Manager (Lógica Global)
class AppManager: ObservableObject {
    @Published var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: "userName") }
    }
    @Published var currentPoints: Int {
        didSet { UserDefaults.standard.set(currentPoints, forKey: "userPoints") }
    }
    // NUEVO: Guardamos la foto como datos (Data)
    @Published var profileImageData: Data? {
        didSet { UserDefaults.standard.set(profileImageData, forKey: "profileImage") }
    }
    
    @Published var currentMood: Mood?
    @Published var accentColor: Color = .blue
    @Published var showConfetti: Bool = false
    
    var currentRank: UserRank { UserRank.getRank(points: currentPoints) }
    
    init() {
        self.userName = UserDefaults.standard.string(forKey: "userName") ?? "Usuario"
        self.currentPoints = UserDefaults.standard.integer(forKey: "userPoints")
        // Recuperamos la foto guardada
        self.profileImageData = UserDefaults.standard.data(forKey: "profileImage")
        checkDailyReset()
    }
    
    func checkDailyReset() {
        let lastLogin = UserDefaults.standard.object(forKey: "lastLoginDate") as? Date ?? Date.distantPast
        if !Calendar.current.isDateInToday(lastLogin) {
            currentMood = nil
        } else {
            if let savedMood = UserDefaults.standard.string(forKey: "todayMood"),
               let mood = Mood(rawValue: savedMood) {
                setMood(mood)
            }
        }
    }
    
    func setMood(_ mood: Mood) {
        withAnimation(.easeInOut(duration: 0.5)) {
            self.currentMood = mood
            self.accentColor = mood.themeColor
        }
        UserDefaults.standard.set(Date(), forKey: "lastLoginDate")
        UserDefaults.standard.set(mood.rawValue, forKey: "todayMood")
    }
    
    func completeTask(item: ReminderItem) {
        let oldRank = currentRank
        var pointsToAdd = item.type.basePoints
        let daysBefore = Calendar.current.dateComponents([.day], from: Date(), to: item.date).day ?? 0
        if daysBefore >= 7 { pointsToAdd += 10 } else if daysBefore >= 3 { pointsToAdd += 5 }
        
        withAnimation {
            currentPoints += pointsToAdd
            item.isCompleted = true
            item.completedDate = Date()
        }
        
        if currentRank != oldRank {
            triggerConfetti()
        }
    }
    
    func triggerConfetti() {
        showConfetti = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.showConfetti = false
        }
    }
}
