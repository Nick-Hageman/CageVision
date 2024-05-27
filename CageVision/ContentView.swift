//
//  ContentView.swift
//  CageVision
//
//  Created by Nick Hageman on 5/26/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import Combine
import Foundation

struct Fighter: Codable {
    let name: String
    let record: String
    let country: String
    let picture: String
}

struct Fight: Identifiable, Codable {
    let id = UUID()
    let weight: String
    let fighterA: Fighter
    let fighterB: Fighter
    
    enum CodingKeys: String, CodingKey {
        case weight
        case fighterA = "fighterA"
        case fighterB = "fighterB"
    }
}

struct UFCEvent: Identifiable, Codable, Equatable {
    let id = UUID()
    let title: String
    let date: String
    let fights: [Fight]
    
    enum CodingKeys: String, CodingKey {
        case title
        case date
        case fights
    }
    
    static func == (lhs: UFCEvent, rhs: UFCEvent) -> Bool {
        return lhs.id == rhs.id // just make them comparable
    }
}

struct UFCEventsResponse: Codable {
    let data: [UFCEvent]
}

class ViewModel : ObservableObject {
    @Published var events: [UFCEvent] = []
    @Published var selectedEvent: UFCEvent?
    
    func fetchData() {
        guard let url = URL(string: "https://mmafightcardsapi.adaptable.app/") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
//            if let jsonString = String(data: data, encoding: .utf8) {
//                print("Recieved JSON: \(jsonString)")
//            }
            
            do {
                let response = try JSONDecoder().decode(UFCEventsResponse.self, from: data)
                DispatchQueue.main.async {
                    self.events = response.data
                    if !self.events.isEmpty {
                        self.selectedEvent = self.events[0]
                    }
                }
            } catch {
                print("Error Decoding JSON: \(error)")
            }
        }.resume()
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    @State private var currentIndex = 0
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button(action: {
                        if currentIndex > 0 {
                            currentIndex -= 1
                            viewModel.selectedEvent = viewModel.events[currentIndex]
                        }
                    }) {
                        Image(systemName: "arrow.left")
                    }
                    ForEach(viewModel.events.indices, id: \.self) { index in
                        Text("*")
                            .foregroundColor(index == currentIndex ? .blue : .gray)
                            .onTapGesture {
                                currentIndex = index
                                viewModel.selectedEvent = viewModel.events[index]
                            }
                    }
                    
                    Button(action: {
                        if currentIndex < viewModel.events.count - 1 {
                            currentIndex += 1
                            viewModel.selectedEvent = viewModel.events[currentIndex]
                        }
                    }) {
                        Image(systemName: "arrow.right")
                    }
                }
                ScrollView {
                    if let selectedEvent = viewModel.selectedEvent {
                        Text("Title: \(selectedEvent.title)")
                            .font(.largeTitle)
                            .padding(.top)
                        
                        Text("Date: \(selectedEvent.date)")
                            .font(.headline)
                            .padding(.top)
                        
                        ScrollView {
                            ForEach(selectedEvent.fights) { fight in
                                VStack(alignment: .leading) {
                                    HStack {
                                        FighterAView(fighter: fight.fighterA)
                                        Spacer()
                                        Text("Weight: \(fight.weight)")
                                            .font(.title)
                                            .bold()
                                        Spacer()
                                        FighterBView(fighter: fight.fighterB)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.white, lineWidth: 1)
                                    )
                                }
                                .padding(.vertical, 5)
                            }
                            .padding()
                        }
                    }
                    
                }
            }
            .onAppear {
                viewModel.fetchData()
            }
            .padding()
            Spacer()
            Text(" ")
            Text(" ")
            Text(" ")
            VStack {
                Model3D(named: "UFC_Octagon") { model in
                    model
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 300, height: 300)
                .position(x: 500, y: 1100)
            }
        }
//        Model3D(named: "UFC_Octagon") { model in
//            model
//                .resizable()www
//                .aspectRatio(contentMode: .fit)
//        } placeholder: {
//            ProgressView()
//        }
    }
}

struct FighterAView: View {
    let fighter: Fighter
    
    var body: some View {
        HStack {
            if let url = URL(string: fighter.country), let imageData = try? Data(contentsOf: url), let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .shadow(radius: 5)
            }
            if let url = URL(string: fighter.picture), let imageData = try? Data(contentsOf: url), let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(radius: 5)
            }
            VStack(alignment: .leading) {
                Text("Name: \(fighter.name)")
                    .font(.headline)
                Text("Record: \(fighter.record)")
                    .font(.subheadline)
            }
        }
    }
}

struct FighterBView: View {
    let fighter: Fighter
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Name: \(fighter.name)")
                    .font(.headline)
                Text("Record: \(fighter.record)")
                    .font(.subheadline)
            }
            if let url = URL(string: fighter.picture), let imageData = try? Data(contentsOf: url), let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .shadow(radius: 5)
            }

            if let url = URL(string: fighter.country), let imageData = try? Data(contentsOf: url), let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .shadow(radius: 5)
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
