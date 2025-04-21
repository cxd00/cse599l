//
//  ContentView.swift
//  cxd599l_a1
//
//  Created by Cynthia on 4/8/25.
//

import SwiftUI
import Charts

struct ContentView: View {
    @ObservedObject var viewModel = MotionView()
    @State var data: [TiltData] = []
    @State var chartTimer = Timer.publish(every: 1/10.0, on: .main, in: .common).autoconnect()
    
    func updateData(_: Date) {
        data = viewModel.tiltHistory
    }
    
    var body: some View {
        VStack {
//            if (viewModel.showChart) {
            Text(viewModel.tiltSummary)
            Chart(data) {
                LineMark(x: .value("Index", $0.index), y: .value("tilt", $0.tilt))
                    .foregroundStyle(by: .value("Data Source", $0.dataSource))
            }
            .onReceive(self.chartTimer, perform: updateData)
//            }
            Spacer()
                            HStack(spacing: 24){
                                Button {
                                    viewModel.startDisplay()
                                    self.chartTimer = Timer.publish(every: 1/10.0, on: .main, in: .common).autoconnect()
                                } label: {
                                    Text("Start Updates")
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
                                    viewModel.stopDisplay()
                                    self.chartTimer.upstream.connect().cancel()
                                } label: {
                                    Text("Stop Updates")
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
                                                .fill(Color.blue)
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
                                                .fill(Color.red)
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
