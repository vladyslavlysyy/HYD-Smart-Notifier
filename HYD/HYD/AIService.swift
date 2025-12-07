//
//  AIService.swift
//  HYD
//
//  Created by Vladyslav Lysyy on 6/12/25.
//

import Foundation

class AIService {
    static let shared = AIService()
    
    struct AIResult {
        var title: String
        var date: Date
        var type: TaskType
    }
    
    func analyzeInput(_ text: String) -> AIResult? {
        // 1. Detectar Fecha y Hora
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        var detectedDate = Date().addingTimeInterval(3600) // Default: dentro de 1 hora

        if let match = matches?.first, let date = match.date {
            detectedDate = date
        }
        
        // 2. Inferir Tipo por palabras clave
        let lowerText = text.lowercased()
        var detectedType: TaskType = .reminder // Default
        
        if lowerText.contains("examen") || lowerText.contains("estudiar") || lowerText.contains("entrega") || lowerText.contains("informe"){
            detectedType = .homework
        } else if lowerText.contains("medico") || lowerText.contains("cita") || lowerText.contains("reunion") {
            detectedType = .appointment
        } else if lowerText.contains("fiesta") || lowerText.contains("cumpleaños") || lowerText.contains("boda") || lowerText.contains("disco") || lowerText.contains("concierto"){
            detectedType = .event
        }
        
        return AIResult(title: text, date: detectedDate, type: detectedType)
    }
}
