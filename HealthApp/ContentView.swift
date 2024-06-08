//
//  ContentView.swift
//  HealthApp
//
//  Created by Sarath krishnaswamy on 04/06/24.
//

import SwiftUI
import AuthenticationServices

struct ContentView: View {
    @State private var userAuthenticated = false

    var body: some View {
        VStack {
            if userAuthenticated {
                HealthDataView()
            } else {
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                // Handle successful authentication
                                print("success")
                                self.userAuthenticated = true
                            }
                        case .failure(let error):
                            // Handle error
                            print(error.localizedDescription)
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(width: 200, height: 45)
            }
        }
    }
}


#Preview {
    ContentView()
}
