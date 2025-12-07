//
//  NotificationManager.swift
//  HYD
//
//  Created by Vladyslav Lysyy on 6/12/25.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    // 1. Pedir permiso al usuario (La primera vez)
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Permiso de notificaciones concedido")
            } else if let error = error {
                print("❌ Error pidiendo permisos: \(error.localizedDescription)")
            }
        }
    }
    
    // 2. Programar los avisos inteligentes (7 días, 3 días, 1 día y Hora exacta)
    func scheduleNotifications(for item: ReminderItem) {
        let content = UNMutableNotificationContent()
        content.title = item.typeString // Ej: "Examen"
        content.sound = .default
        
        // Lista de momentos para avisar (Días antes)
        let intervals = [7, 3, 1, 0] // 0 es el día del evento
        
        for daysBefore in intervals {
            // Calculamos la fecha del aviso
            guard let triggerDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: item.date) else { continue }
            
            // SOLO programamos si la fecha es en el FUTURO
            // (Esto evita que te avise "7 días antes" si el evento es mañana)
            if triggerDate > Date() {
                
                // Personalizamos el mensaje
                if daysBefore == 0 {
                    content.body = "¡Es ahora! \(item.title)"
                } else if daysBefore == 1 {
                    content.body = "Mañana: \(item.title)"
                } else {
                    content.body = "Faltan \(daysBefore) días para: \(item.title)"
                }
                
                // Creamos el trigger (disparador)
                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                
                // Identificador único para cada aviso
                let requestID = "\(item.id.uuidString)-\(daysBefore)"
                let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)
                
                // Enviamos al sistema
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error { print("Error programando: \(error)") }
                }
            }
        }
    }
}
