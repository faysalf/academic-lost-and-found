import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showCreatePost = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                BrowseView()
            }
            .tabItem {
                Label("Browse", systemImage: "list.bullet.below.rectangle")
            }
            .tag(0)

            NavigationStack {
                MyPostsView()
            }
            .tabItem {
                Label("My Posts", systemImage: "person.text.rectangle")
            }
            .tag(1)

            Color.clear
                .tabItem {
                    Label("New Post", systemImage: "plus.circle.fill")
                }
                .tag(2)
        }
        .sheet(isPresented: $showCreatePost) {
            NavigationStack {
                CreatePostView()
            }
        }
        .onChange(of: selectedTab) { _, new in
            if new == 2 {
                showCreatePost = true
                selectedTab = 0
            }
        }
    }
}
