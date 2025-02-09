//
//  EventDetailBar.swift
//  damus
//
//  Created by William Casarin on 2023-01-08.
//

import SwiftUI

struct EventDetailBar: View {
    let state: DamusState
    let target: String
    let target_pk: String
    
    @ObservedObject var bar: ActionBarModel
    
    init (state: DamusState, target: String, target_pk: String) {
        self.state = state
        self.target = target
        self.target_pk = target_pk
        self._bar = ObservedObject(wrappedValue: make_actionbar_model(ev: target, damus: state))
        
    }
    
    var body: some View {
        HStack {
            if bar.boosts > 0 {
                NavigationLink(destination: RepostsView(damus_state: state, model: RepostsModel(state: state, target: target))) {
                    let noun = Text(verbatim: "\(repostsCountString(bar.boosts))").foregroundColor(.gray)
                    Text("\(Text("\(bar.boosts)").font(.body.bold())) \(noun)", comment: "Sentence composed of 2 variables to describe how many reposts. In source English, the first variable is the number of reposts, and the second variable is 'Repost' or 'Reposts'.")
                }
                .buttonStyle(PlainButtonStyle())
            }

            if bar.likes > 0 {
                NavigationLink(destination: ReactionsView(damus_state: state, model: ReactionsModel(state: state, target: target))) {
                    let noun = Text(verbatim: "\(reactionsCountString(bar.likes))").foregroundColor(.gray)
                    Text("\(Text("\(bar.likes)").font(.body.bold())) \(noun)", comment: "Sentence composed of 2 variables to describe how many reactions there are on a post. In source English, the first variable is the number of reactions, and the second variable is 'Reaction' or 'Reactions'.")
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if bar.zaps > 0 {
                let dst = ZapsView(state: state, target: .note(id: target, author: target_pk))
                NavigationLink(destination: dst) {
                    let noun = Text(verbatim: "\(zapsCountString(bar.zaps))").foregroundColor(.gray)
                    Text("\(Text("\(bar.zaps)").font(.body.bold())) \(noun)", comment: "Sentence composed of 2 variables to describe how many zap payments there are on a post. In source English, the first variable is the number of zap payments, and the second variable is 'Zap' or 'Zaps'.")
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

func repostsCountString(_ count: Int, locale: Locale = Locale.current) -> String {
    let bundle = bundleForLocale(locale: locale)
    return String(format: bundle.localizedString(forKey: "reposts_count", value: nil, table: nil), locale: locale, count)
}

func reactionsCountString(_ count: Int, locale: Locale = Locale.current) -> String {
    let bundle = bundleForLocale(locale: locale)
    return String(format: bundle.localizedString(forKey: "reactions_count", value: nil, table: nil), locale: locale, count)
}

func zapsCountString(_ count: Int, locale: Locale = Locale.current) -> String {
    let bundle = bundleForLocale(locale: locale)
    return String(format: bundle.localizedString(forKey: "zaps_count", value: nil, table: nil), locale: locale, count)
}

struct EventDetailBar_Previews: PreviewProvider {
    static var previews: some View {
        EventDetailBar(state: test_damus_state(), target: "", target_pk: "")
    }
}
