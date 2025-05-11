import SwiftUI

struct NoteView: View {
    let note: Note
    @State private var isExpanded = false
    @State private var isLiked = false
    @State private var isSaved = false
    @State private var hashtagColors: [Color] = []
    
    init(note: Note) {
        self.note = note
        _isLiked = State(initialValue: note.isLiked)
        _isSaved = State(initialValue: note.isSaved)
        _hashtagColors = State(initialValue: generateRandomColors(count: note.hashtags.count))
    }
    
    private func generateRandomColors(count: Int) -> [Color] {
        return (0..<count).map { _ in
            Color(
                red: Double.random(in: 0...1),
                green: Double.random(in: 0...1),
                blue: Double.random(in: 0...1)
            )
        }
    }
    
    private func textColor(for backgroundColor: Color) -> Color {
        let components = backgroundColor.cgColor?.components ?? [0, 0, 0, 1]
        let brightness = (components[0] * 299 + components[1] * 587 + components[2] * 114) / 1000
        return brightness > 0.5 ? .black : .white
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.author)
                    .font(.headline)
                Spacer()
                Text(note.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Text(note.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(note.content)
                .lineLimit(isExpanded ? nil : 3)
                .font(.body)
            
            if !note.hashtags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(zip(note.hashtags, hashtagColors)), id: \.0) { hashtag, color in
                            Text(hashtag)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(color)
                                .foregroundColor(textColor(for: color))
                                .cornerRadius(15)
                        }
                    }
                }
            }
            
            HStack {
                Button(action: {
                    isLiked.toggle()
                }) {
                    HStack {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .gray)
                        Text("\(note.likesCount + (isLiked ? 1 : 0))")
                    }
                }
                
                Spacer()
                
                Button(action: {
                    isSaved.toggle()
                }) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .foregroundColor(isSaved ? .blue : .gray)
                }
                
                Spacer()
                
                if !isExpanded && note.content.count > 100 {
                    Button(action: {
                        isExpanded.toggle()
                    }) {
                        Text("...")
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
