//
//  DesignSystem.swift
//  HYD
//
//  Created by Vladyslav Lysyy on 6/12/25.
//

import SwiftUI

// MARK: - Efecto Glassmorphism
struct GlassContainer: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 10)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(LinearGradient(colors: [.white.opacity(0.4), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
    }
}

extension View {
    func glassStyle() -> some View {
        self.modifier(GlassContainer())
    }
}

// MARK: - Sistema de Confeti
struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<50) { i in
                Circle()
                    .fill(Color(
                        red: .random(in: 0...1),
                        green: .random(in: 0...1),
                        blue: .random(in: 0...1)
                    ))
                    .frame(width: 8, height: 8)
                    .modifier(ConfettiParticle(index: i))
                    .opacity(animate ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2.5)) {
                animate = true
            }
        }
    }
}

struct ConfettiParticle: ViewModifier {
    let index: Int
    @State private var time: Double = 0.0
    
    func body(content: Content) -> some View {
        content
            .offset(x: time * Double.random(in: -200...200), y: time * Double.random(in: -200...400))
            .rotationEffect(.degrees(time * 360))
            .onAppear {
                withAnimation(.easeOut(duration: 2.5)) {
                    time = 1.0
                }
            }
    }
}
