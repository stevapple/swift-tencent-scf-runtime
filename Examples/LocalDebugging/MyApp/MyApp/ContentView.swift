//===------------------------------------------------------------------------------------===//
//
// This source file is part of the SwiftTencentSCFRuntime open source project
//
// Copyright (c) 2021 stevapple and the SwiftTencentSCFRuntime project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftTencentSCFRuntime project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===------------------------------------------------------------------------------------===//

import Shared
import SwiftUI

struct ContentView: View {
    @State var name: String = ""
    @State var password: String = ""
    @State var response: String = ""
    @State private var isLoading: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            TextField("Username", text: $name)
            SecureField("Password", text: $password)
            Button {
                Task {
                    isLoading = true
                    response = await register()
                    isLoading = false
                }
            } label: {
                Text("Register")
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.black)
                    .border(Color.black, width: 2)
                    .opacity(isLoading ? 0 : 1)
                    .overlay {
                        if isLoading {
                            ProgressView()
                        }
                    }
            }
            Text(response)
        }.padding(100)
    }

    func register() async -> String {
        guard let url = URL(string: "http://localhost:9001/invoke") else {
            fatalError("invalid url")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        guard let jsonRequest = try? JSONEncoder().encode(Request(name: self.name, password: self.password)) else {
            fatalError("encoding error")
        }
        request.httpBody = jsonRequest

        do {
            let (data, urlResponse) = try await URLSession.shared.data(for: request)

            guard let httpResponse = urlResponse as? HTTPURLResponse else {
                return "invalid response, expected HTTPURLResponse"
            }
            guard httpResponse.statusCode == 200 else {
                return "invalid response code: \(httpResponse.statusCode)"
            }

            let response = try JSONDecoder().decode(Response.self, from: data)
            return response.message
        } catch {
            return error.localizedDescription
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
