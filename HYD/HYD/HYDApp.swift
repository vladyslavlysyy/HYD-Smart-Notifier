import SwiftUI
import SwiftData
import UserNotifications

@main
struct HYDApp: App {
    @StateObject var appManager = AppManager()
    

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ReminderItem.self,
        ])
        
        // GUARDAR EN DISCO DURO
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("ERROR CRÍTICO DE BASE DE DATOS: Los datos antiguos no coinciden con el código nuevo. BORRAR LA APP del simulador y volver a instalarla para corregirlo. Error: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if appManager.currentMood == nil {
                    WelcomeView()
                } else {
                    DashboardView()
                }
            }
            .environmentObject(appManager)
            .preferredColorScheme(.dark)
            .onAppear {
                // Limpieza automática de datos muy viejos
                cleanOldHistory()
                
                // Pedir permisos de notificaciones al arrancar
                NotificationManager.shared.requestPermission()
            }
        }
        .modelContainer(sharedModelContainer)
    }
    
    func cleanOldHistory() {
        let context = sharedModelContainer.mainContext
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        
        // Intentamos limpiar el historial antiguo sin bloquear la app
        try? context.delete(model: ReminderItem.self, where: #Predicate { $0.isCompleted && $0.date < sevenDaysAgo })
    }
}
