//
//  ProgressView.swift
//  Cloud ToDo
//
//  Created by Philipp on 15.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import SwiftUI

enum ProgressIndicatorPreference: PreferenceKey {
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }

    static var defaultValue: Bool = false
}

struct ProgressView: View {
    @State var progress: Double = 0

    let strokeColor = Color.primary
    let backgroundColor = Color(.secondarySystemBackground)

    let size: CGFloat = 60
    let lineWidth: CGFloat = 10.0
    let timer = Timer.publish(every: 0.25, on: .main, in: .default).autoconnect()
    let twoPi = 2.0 * .pi
    let angle = Angle(radians: -1.9 * .pi)

    var body: some View {
        Circle()
            .stroke(
                AngularGradient(gradient: Gradient(colors: [strokeColor, Color.white]), center: .center, startAngle: .radians(progress * twoPi), endAngle: .radians(progress * twoPi) + angle),
                lineWidth: lineWidth
            )
            .frame(width: size, height: size)

            .frame(maxWidth: 2*size, maxHeight: 2*size)
            .background(backgroundColor.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.secondary, lineWidth: 1.0)
            )
            .cornerRadius(16)

            .onReceive(timer) { (time) in
                withAnimation(.linear(duration: 0.25)) {
                    self.progress += 0.25
                }
                if self.progress >= 1 {
                    self.progress -= 1
                }
            }
    }
}

extension View {
    func withProgressView(_ enabled: Binding<Bool>) -> some View {
        return ZStack {
                self
                    .onPreferenceChange(ProgressIndicatorPreference.self) { (shouldEnable) in
                        enabled.wrappedValue = shouldEnable
                    }

                ProgressView()
                //ActivityIndicatorView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.3))
                    .opacity(enabled.wrappedValue ? 1 : 0)
            }
    }

    func loading(_ state: Bool) -> some View {
        return self.preference(key: ProgressIndicatorPreference.self, value: state)
    }
}

struct ProgressView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                Spacer()
            }
            .navigationBarTitle("Loading...")
        }
        .withProgressView(.constant(true))
    }
}
