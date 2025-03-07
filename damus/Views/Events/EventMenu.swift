//
//  EventMenu.swift
//  damus
//
//  Created by William Casarin on 2023-01-23.
//

import SwiftUI

struct EventMenuContext: View {
    let event: NostrEvent
    let keypair: Keypair
    let target_pubkey: String
    let bookmarks: BookmarksManager
    
    var body: some View {
        HStack {
            Menu {
                
                MenuItems(event: event, keypair: keypair, target_pubkey: target_pubkey, bookmarks: bookmarks)
                
            } label: {
                Label(NSLocalizedString("", comment: "Context menu"), systemImage: "ellipsis")
                    .foregroundColor(Color.gray)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {}
        
    }
}

struct MenuItems: View {
    let event: NostrEvent
    let keypair: Keypair
    let target_pubkey: String
    let bookmarks: BookmarksManager
    
    @State private var isBookmarked: Bool = false
    
    init(event: NostrEvent, keypair: Keypair, target_pubkey: String, bookmarks: BookmarksManager) {
        let bookmarked = bookmarks.isBookmarked(event)
        self._isBookmarked = State(initialValue: bookmarked)
        
        self.bookmarks = bookmarks
        self.event = event
        self.keypair = keypair
        self.target_pubkey = target_pubkey
    }
    
    var body: some View {

        Group {
            Button {
                UIPasteboard.general.string = event.get_content(keypair.privkey)
            } label: {
                Label(NSLocalizedString("Copy Text", comment: "Context menu option for copying the text from an note."), systemImage: "doc.on.doc")
            }

            Button {
                UIPasteboard.general.string = bech32_pubkey(target_pubkey)
            } label: {
                Label(NSLocalizedString("Copy User Pubkey", comment: "Context menu option for copying the ID of the user who created the note."), systemImage: "person")
            }

            Button {
                UIPasteboard.general.string = bech32_note_id(event.id) ?? event.id
            } label: {
                Label(NSLocalizedString("Copy Note ID", comment: "Context menu option for copying the ID of the note."), systemImage: "note.text")
            }

            Button {
                UIPasteboard.general.string = event_to_json(ev: event)
            } label: {
                Label(NSLocalizedString("Copy Note JSON", comment: "Context menu option for copying the JSON text from the note."), systemImage: "square.on.square")
            }
            
            Button {
                self.bookmarks.updateBookmark(event)
                isBookmarked = self.bookmarks.isBookmarked(event)
            } label: {
                let imageName = isBookmarked ? "bookmark.fill" : "bookmark"
                let removeBookmarkString = NSLocalizedString("Remove Bookmark", comment: "Context menu option for removing a note bookmark.")
                let addBookmarkString = NSLocalizedString("Add Bookmark", comment: "Context menu option for adding a note bookmark.")
                Label(isBookmarked ? removeBookmarkString : addBookmarkString, systemImage: imageName)
            }

            Button {
                NotificationCenter.default.post(name: .broadcast_event, object: event)
            } label: {
                Label(NSLocalizedString("Broadcast", comment: "Context menu option for broadcasting the user's note to all of the user's connected relay servers."), systemImage: "globe")
            }
            
            // Only allow reporting if logged in with private key and the currently viewed profile is not the logged in profile.
            if keypair.pubkey != target_pubkey && keypair.privkey != nil {
                Button(role: .destructive) {
                    let target: ReportTarget = .note(ReportNoteTarget(pubkey: target_pubkey, note_id: event.id))
                    notify(.report, target)
                } label: {
                    Label(NSLocalizedString("Report", comment: "Context menu option for reporting content."), systemImage: "exclamationmark.bubble")
                }
                
                Button(role: .destructive) {
                    notify(.block, target_pubkey)
                } label: {
                    Label(NSLocalizedString("Block", comment: "Context menu option for blocking users."), systemImage: "exclamationmark.octagon")
                }
            }
        }
    }
}

/*
struct EventMenu: UIViewRepresentable {
    
    typealias UIViewType = UIButton

    let saveAction = UIAction(title: "") { action in }
    let saveMenu = UIMenu(title: "", children: [
        UIAction(title: "First Menu Item", image: UIImage(systemName: "nameOfSFSymbol")) { action in
            //code action for menu item
        },
        UIAction(title: "First Menu Item", image: UIImage(systemName: "nameOfSFSymbol")) { action in
            //code action for menu item
        },
        UIAction(title: "First Menu Item", image: UIImage(systemName: "nameOfSFSymbol")) { action in
            //code action for menu item
        },
    ])

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        button.showsMenuAsPrimaryAction = true
        button.menu = saveMenu
        
        return button
    }
    
    func updateUIView(_ uiView: UIButton, context: Context) {
        uiView.setImage(UIImage(systemName: "plus"), for: .normal)
    }
}

struct EventMenu_Previews: PreviewProvider {
    static var previews: some View {
        EventMenu(event: test_event, privkey: nil, pubkey: test_event.pubkey)
    }
}

*/
