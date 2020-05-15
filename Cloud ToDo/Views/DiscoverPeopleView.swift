//
//  DiscoverPeopleView.swift
//  Cloud ToDo
//
//  Created by Philipp on 13.05.20.
//  Copyright © 2020 Philipp. All rights reserved.
//

import SwiftUI
import CloudKit

struct DiscoverPeopleView: View {
    typealias IdentityCallBack = (CKUserIdentity)->()
    @Environment(\.presentationMode) var presentationMode

    let selectedPerson: IdentityCallBack? = nil
    @State private var identities = [CKUserIdentity]()
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationView {
            List(identities, id: \.userRecordID?.recordName) { identity in
                Button(action: { self.selectedPerson?(identity) }) {
                    Text(self.formatter.string(from: identity.nameComponents!))
                }
                .foregroundColor(Color.primary)
                .environment(\.isEnabled, self.selectedPerson != nil)
            }
            .buttonStyle(BorderlessButtonStyle())
            .onAppear {
                self.discoverFriends()
            }
            .navigationBarTitle("Contacts")
            .navigationBarItems(trailing: Button("Done", action: {
                self.presentationMode.wrappedValue.dismiss()
            }))
        }
        .withProgressView($isLoading)
    }

    private let formatter = PersonNameComponentsFormatter()


    func discoverFriends() {
        isLoading = true
        CKContainer(identifier: "iCloud.com.yourcompany.Cloud-ToDo.todo").discoverAllIdentities(completionHandler: { users, error in
            guard let userIdentities = users, error == nil else {

                if let ckerror = error as? CKError {
                    print("CloudKit Error")
                    for key in ckerror.errorUserInfo.keys {
                        if let value = ckerror.errorUserInfo[key] {
                            print("    \(key): \(value)")
                        }
                    }
                    print("fetch user error \(String(describing: ckerror.errorUserInfo[NSLocalizedDescriptionKey]))")
                }
                else {
                    print("fetch user error " + error!.localizedDescription)
                }

                DispatchQueue.main.async {
                    self.isLoading = false
                }

                return
            }

            DispatchQueue.main.async {
                self.isLoading = false
                self.identities = userIdentities
            }
        })
    }
}

struct DiscoverPeopleView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverPeopleView()
    }
}
