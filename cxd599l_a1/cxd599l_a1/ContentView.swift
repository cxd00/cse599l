//
//  ContentView.swift
//  cxd599l_a1
//
//  Created by Cynthia on 4/8/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = MotionView()
    let timer = Timer.publish(every: 1/60.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
//            Text("Hello, world!")
            Text("Tilt").onReceive(timer) { time in
                
            }
            Text(viewModel.accelDisplay)
            Text(viewModel.gyroDisplay)
            Text(viewModel.accelSummary)
            Text(viewModel.gyroSummary)
            Text(viewModel.tiltSummary)
            Spacer()
                            HStack(spacing: 24){
                                Button {
                                    viewModel.stopDisplay()
                                } label: {
                                    Text("Stop Updates")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 42)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.secondary)
                                        )
                                }
                                Button {
                                    viewModel.startDisplay()
                                } label: {
                                    Text("Start Updates")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 42)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.orange)
                                        )
                                }
                                Button {
                                    viewModel.getDataSummary()
                                } label: {
                                    Text("Summarize")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 42)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.orange)
                                        )
                                }
                                Button {
                                    viewModel.clear()
                                } label: {
                                    Text("Clear")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 42)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.orange)
                                        )
                                }
                            }
                            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
