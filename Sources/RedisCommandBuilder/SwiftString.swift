extension StringProtocol {
    func swiftFunction() -> String {
        self
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
            .camelCased(capitalize: false)
    }

    func swiftArgument() -> String {
        self
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
            .camelCased(capitalize: false)
    }

    func camelCased(capitalize: Bool) -> String {
        let items = self.split(separator: "_")
        let firstWord = items.first!
        let firstWordProcessed: String
        if capitalize {
            firstWordProcessed = firstWord.upperFirst()
        } else {
            firstWordProcessed = firstWord.lowerFirstWord()
        }
        let remainingItems = items.dropFirst().map { word -> String in
            if word.allLetterIsSnakeUppercased() {
                return String(word)
            }
            return word.capitalized
        }
        return firstWordProcessed + remainingItems.joined()
    }

    private func lowerFirst() -> String {
        String(self[startIndex]).lowercased() + self[index(after: startIndex)...]
    }

    fileprivate func upperFirst() -> String {
        String(self[self.startIndex]).uppercased() + self[index(after: startIndex)...]
    }

    /// Lowercase first letter, or if first word is an uppercase acronym then lowercase the whole of the acronym
    fileprivate func lowerFirstWord() -> String {
        var firstLowercase = self.startIndex
        var lastUppercaseOptional: Self.Index?
        // get last uppercase character, first lowercase character
        while firstLowercase != self.endIndex, self[firstLowercase].isSnakeUppercase() {
            lastUppercaseOptional = firstLowercase
            firstLowercase = self.index(after: firstLowercase)
        }
        // if first character was never set first character must be lowercase
        guard let lastUppercase = lastUppercaseOptional else {
            return String(self)
        }
        if firstLowercase == self.endIndex {
            // if first lowercase letter is the end index then whole word is uppercase and
            // should be wholly lowercased
            return self.lowercased()
        } else if lastUppercase == self.startIndex {
            // if last uppercase letter is the first letter then only lower that character
            return self.lowerFirst()
        } else {
            // We have an acronym at the start, lowercase the whole of it
            return self[startIndex..<lastUppercase].lowercased() + self[lastUppercase...]
        }
    }

    fileprivate func allLetterIsSnakeUppercased() -> Bool {
        for c in self {
            if !c.isSnakeUppercase() {
                return false
            }
        }
        return true
    }
}

extension Character {
    fileprivate func isSnakeUppercase() -> Bool {
        self.isNumber || ("A"..."Z").contains(self) || self == "_"
    }
}
