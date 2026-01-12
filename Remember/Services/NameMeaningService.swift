import Foundation

/// Service for looking up name meanings/etymology to help with memory
final class NameMeaningService {
    static let shared = NameMeaningService()

    private init() {}

    /// Look up the meaning of a first name
    func meaning(for name: String) -> String? {
        let normalized = name.lowercased().trimmingCharacters(in: .whitespaces)

        // Extract first name if full name provided
        let firstName = normalized.components(separatedBy: " ").first ?? normalized

        return nameMeanings[firstName]
    }

    // Common first names and their meanings
    private let nameMeanings: [String: String] = [
        // A
        "adam": "From Hebrew, meaning 'earth' or 'man'",
        "adrian": "From Latin, meaning 'from Hadria' (dark one)",
        "aiden": "From Irish Gaelic, meaning 'little fire'",
        "alex": "From Greek, meaning 'defender of the people'",
        "alexander": "From Greek, meaning 'defender of the people'",
        "alexandra": "From Greek, meaning 'defender of the people'",
        "alice": "From German, meaning 'noble'",
        "amanda": "From Latin, meaning 'worthy of love'",
        "amber": "From Arabic, meaning 'jewel'",
        "amy": "From Latin, meaning 'beloved'",
        "andrea": "From Greek, meaning 'strong and brave'",
        "andrew": "From Greek, meaning 'strong and manly'",
        "angela": "From Greek, meaning 'messenger of God'",
        "anna": "From Hebrew, meaning 'grace'",
        "anthony": "From Latin, meaning 'priceless'",
        "antonio": "From Latin, meaning 'priceless'",
        "ashley": "From English, meaning 'ash tree meadow'",

        // B
        "benjamin": "From Hebrew, meaning 'son of the right hand'",
        "brandon": "From English, meaning 'hill covered with broom'",
        "brian": "From Celtic, meaning 'noble' or 'high'",
        "brittany": "From Latin, referring to the region of Britain",

        // C
        "carlos": "From Spanish/German, meaning 'free man'",
        "carmen": "From Hebrew/Latin, meaning 'garden' or 'song'",
        "caroline": "From German, meaning 'free woman'",
        "catherine": "From Greek, meaning 'pure'",
        "charles": "From German, meaning 'free man'",
        "charlotte": "From French, meaning 'free woman'",
        "chloe": "From Greek, meaning 'blooming' or 'green shoot'",
        "christian": "From Latin, meaning 'follower of Christ'",
        "christina": "From Latin, meaning 'follower of Christ'",
        "christopher": "From Greek, meaning 'bearer of Christ'",
        "claire": "From Latin, meaning 'bright' or 'clear'",
        "clara": "From Latin, meaning 'bright' or 'clear'",
        "connor": "From Irish, meaning 'lover of hounds'",

        // D
        "daniel": "From Hebrew, meaning 'God is my judge'",
        "david": "From Hebrew, meaning 'beloved'",
        "diana": "From Latin, meaning 'divine' (Roman goddess)",
        "diego": "From Spanish, meaning 'supplanter'",
        "dylan": "From Welsh, meaning 'son of the sea'",

        // E
        "edward": "From English, meaning 'wealthy guardian'",
        "elena": "From Greek, meaning 'shining light'",
        "elizabeth": "From Hebrew, meaning 'pledged to God'",
        "emily": "From Latin, meaning 'industrious' or 'striving'",
        "emma": "From German, meaning 'whole' or 'universal'",
        "eric": "From Norse, meaning 'eternal ruler'",
        "ethan": "From Hebrew, meaning 'strong' or 'enduring'",
        "eva": "From Hebrew, meaning 'life'",
        "evan": "From Welsh, meaning 'young warrior'",

        // F
        "fernando": "From Spanish/German, meaning 'bold voyager'",
        "francisco": "From Italian, meaning 'free man'",
        "frank": "From German, meaning 'free man'",

        // G
        "gabriel": "From Hebrew, meaning 'God is my strength'",
        "grace": "From Latin, meaning 'charm' or 'blessing'",
        "gregory": "From Greek, meaning 'watchful'",

        // H
        "hannah": "From Hebrew, meaning 'grace' or 'favor'",
        "heather": "From English, meaning 'evergreen flowering plant'",
        "henry": "From German, meaning 'ruler of the home'",
        "hugo": "From German, meaning 'mind' or 'intellect'",

        // I
        "ian": "From Scottish, meaning 'God is gracious'",
        "isabella": "From Hebrew, meaning 'devoted to God'",
        "ivan": "From Russian, meaning 'God is gracious'",

        // J
        "jack": "From English, meaning 'God is gracious'",
        "jacob": "From Hebrew, meaning 'supplanter'",
        "james": "From Hebrew, meaning 'supplanter'",
        "jane": "From Hebrew, meaning 'God is gracious'",
        "jason": "From Greek, meaning 'healer'",
        "javier": "From Basque, meaning 'new house'",
        "jennifer": "From Welsh, meaning 'white wave'",
        "jeremy": "From Hebrew, meaning 'God will uplift'",
        "jessica": "From Hebrew, meaning 'God beholds'",
        "john": "From Hebrew, meaning 'God is gracious'",
        "jonathan": "From Hebrew, meaning 'God has given'",
        "jordan": "From Hebrew, meaning 'flowing down'",
        "jose": "From Hebrew, meaning 'God will increase'",
        "joseph": "From Hebrew, meaning 'God will increase'",
        "joshua": "From Hebrew, meaning 'God is salvation'",
        "juan": "From Hebrew, meaning 'God is gracious'",
        "julia": "From Latin, meaning 'youthful'",
        "julian": "From Latin, meaning 'youthful'",
        "justin": "From Latin, meaning 'just' or 'fair'",

        // K
        "karen": "From Danish, meaning 'pure'",
        "kate": "From Greek, meaning 'pure'",
        "katherine": "From Greek, meaning 'pure'",
        "kelly": "From Irish, meaning 'warrior'",
        "kevin": "From Irish, meaning 'handsome'",
        "kim": "From English, meaning 'royal fortress meadow'",
        "kyle": "From Gaelic, meaning 'narrow strait'",

        // L
        "laura": "From Latin, meaning 'laurel' (symbol of victory)",
        "lauren": "From Latin, meaning 'laurel'",
        "leonardo": "From German, meaning 'brave lion'",
        "lily": "From Latin, meaning 'pure' (the flower)",
        "linda": "From Spanish, meaning 'beautiful'",
        "lisa": "From Hebrew, meaning 'pledged to God'",
        "lucas": "From Greek, meaning 'bringer of light'",
        "luis": "From German, meaning 'famous warrior'",
        "luke": "From Greek, meaning 'bringer of light'",

        // M
        "madison": "From English, meaning 'son of Maud'",
        "manuel": "From Hebrew, meaning 'God is with us'",
        "marcos": "From Latin, meaning 'dedicated to Mars'",
        "marcus": "From Latin, meaning 'dedicated to Mars'",
        "margaret": "From Greek, meaning 'pearl'",
        "maria": "From Hebrew, meaning 'beloved' or 'bitter'",
        "mark": "From Latin, meaning 'dedicated to Mars'",
        "martin": "From Latin, meaning 'of Mars' (warrior)",
        "mary": "From Hebrew, meaning 'beloved' or 'bitter'",
        "matthew": "From Hebrew, meaning 'gift of God'",
        "maya": "From Sanskrit, meaning 'illusion' or 'magic'",
        "megan": "From Welsh, meaning 'pearl'",
        "melissa": "From Greek, meaning 'honeybee'",
        "michael": "From Hebrew, meaning 'who is like God'",
        "michelle": "From Hebrew, meaning 'who is like God'",
        "miguel": "From Hebrew, meaning 'who is like God'",
        "mia": "From Scandinavian, meaning 'beloved'",

        // N
        "nancy": "From Hebrew, meaning 'grace'",
        "natalie": "From Latin, meaning 'birthday of the Lord'",
        "nathan": "From Hebrew, meaning 'he gave'",
        "nicholas": "From Greek, meaning 'victory of the people'",
        "nicole": "From Greek, meaning 'victory of the people'",
        "noah": "From Hebrew, meaning 'rest' or 'comfort'",

        // O
        "oliver": "From Latin, meaning 'olive tree'",
        "olivia": "From Latin, meaning 'olive tree'",
        "oscar": "From Irish, meaning 'deer friend'",
        "owen": "From Welsh, meaning 'young warrior'",

        // P
        "pablo": "From Latin, meaning 'small' or 'humble'",
        "patricia": "From Latin, meaning 'noble'",
        "patrick": "From Latin, meaning 'noble'",
        "paul": "From Latin, meaning 'small' or 'humble'",
        "peter": "From Greek, meaning 'rock'",
        "philip": "From Greek, meaning 'lover of horses'",

        // R
        "rachel": "From Hebrew, meaning 'ewe' (gentleness)",
        "rafael": "From Hebrew, meaning 'God has healed'",
        "raymond": "From German, meaning 'wise protector'",
        "rebecca": "From Hebrew, meaning 'to bind'",
        "ricardo": "From German, meaning 'powerful ruler'",
        "richard": "From German, meaning 'powerful ruler'",
        "robert": "From German, meaning 'bright fame'",
        "roberto": "From German, meaning 'bright fame'",
        "rosa": "From Latin, meaning 'rose'",
        "ryan": "From Irish, meaning 'little king'",

        // S
        "samantha": "From Hebrew, meaning 'listener'",
        "samuel": "From Hebrew, meaning 'heard by God'",
        "sandra": "From Greek, meaning 'defender of mankind'",
        "santiago": "From Hebrew, meaning 'supplanter'",
        "sara": "From Hebrew, meaning 'princess'",
        "sarah": "From Hebrew, meaning 'princess'",
        "scott": "From Gaelic, meaning 'from Scotland'",
        "sean": "From Irish, meaning 'God is gracious'",
        "sebastian": "From Greek, meaning 'venerable'",
        "sergio": "From Latin, meaning 'servant'",
        "sofia": "From Greek, meaning 'wisdom'",
        "sophia": "From Greek, meaning 'wisdom'",
        "stephanie": "From Greek, meaning 'crowned one'",
        "stephen": "From Greek, meaning 'crown' or 'wreath'",
        "steven": "From Greek, meaning 'crown' or 'wreath'",
        "susan": "From Hebrew, meaning 'lily'",

        // T
        "taylor": "From English, meaning 'tailor'",
        "teresa": "From Greek, meaning 'to harvest'",
        "thomas": "From Aramaic, meaning 'twin'",
        "timothy": "From Greek, meaning 'honoring God'",
        "tyler": "From English, meaning 'tile maker'",

        // V
        "valentina": "From Latin, meaning 'strong' or 'healthy'",
        "vanessa": "From Greek, meaning 'butterfly'",
        "victoria": "From Latin, meaning 'victory'",
        "vincent": "From Latin, meaning 'conquering'",

        // W
        "william": "From German, meaning 'resolute protector'",

        // Z
        "zachary": "From Hebrew, meaning 'God remembers'",
        "zoe": "From Greek, meaning 'life'"
    ]
}
