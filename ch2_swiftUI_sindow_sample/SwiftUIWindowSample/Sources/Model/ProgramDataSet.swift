public struct ProgramDataSet: Identifiable, Hashable, Codable {
    public var id: String
    var title: String
    var description: String
    var imageName: String
    var difficulty: Int
    var talkPromptData: TalkPromptDataModel

    init(
        id: String,
        title: String,
        description: String,
        imageName: String,
        difficulty: Int,
        talkPromptData: TalkPromptDataModel
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.imageName = imageName
        self.difficulty = difficulty
        self.talkPromptData = talkPromptData
    }
}
